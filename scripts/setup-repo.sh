#!/usr/bin/env bash
# One-shot repository governance setup, reusable for every role repo:
#   - squash-only merges, commit title = PR title, auto-delete merged branches
#   - Actions token read-write + allowed to create PRs (release-please needs it)
#   - "main-protection" ruleset: PR required, required status checks,
#     no force-push / branch deletion; repo admin keeps an emergency bypass
#
# Usage: setup-repo.sh <owner/repo> [required-checks-csv]
# Requires: gh (authenticated with admin rights on the repo), jq.
#
# Note: run this AFTER the first CI run on the repo, otherwise the required
# check contexts will not exist yet (GitHub matches them by name).
set -euo pipefail

REPO="${1:?usage: setup-repo.sh <owner/repo> [required-checks-csv]}"
CHECKS="${2:-lint,molecule (debian12),molecule (ubuntu2404),molecule (rockylinux9),pr-title}"

echo ">> $REPO: merge policy (squash-only, PR title as message, auto-delete branches)"
gh api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F squash_merge_commit_title=PR_TITLE \
  -F squash_merge_commit_message=PR_BODY \
  -F delete_branch_on_merge=true >/dev/null

echo ">> $REPO: Actions workflow token = read-write, may create PRs"
gh api -X PUT "repos/$REPO/actions/permissions/workflow" \
  -F default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=true >/dev/null

echo ">> $REPO: ruleset 'main-protection' (required checks: $CHECKS)"
checks_json=$(jq -cn --arg csv "$CHECKS" '[$csv | split(",")[] | {context: .}]')
# actor_id 5 + RepositoryRole = repository admin (emergency bypass).
ruleset=$(jq -cn --argjson checks "$checks_json" '{
  name: "main-protection",
  target: "branch",
  enforcement: "active",
  conditions: { ref_name: { include: ["~DEFAULT_BRANCH"], exclude: [] } },
  bypass_actors: [
    { actor_id: 5, actor_type: "RepositoryRole", bypass_mode: "always" }
  ],
  rules: [
    { type: "deletion" },
    { type: "non_fast_forward" },
    { type: "pull_request", parameters: {
        required_approving_review_count: 0,
        dismiss_stale_reviews_on_push: false,
        require_code_owner_review: false,
        require_last_push_approval: false,
        required_review_thread_resolution: false } },
    { type: "required_status_checks", parameters: {
        strict_required_status_checks_policy: false,
        required_status_checks: $checks } }
  ]
}')

existing=$(gh api "repos/$REPO/rulesets" --jq \
  '[.[] | select(.name == "main-protection")][0].id // empty' 2>/dev/null || true)
if [[ -n "$existing" ]]; then
  gh api -X PUT "repos/$REPO/rulesets/$existing" --input - <<<"$ruleset" >/dev/null
  echo "   updated existing ruleset (#$existing)"
else
  gh api -X POST "repos/$REPO/rulesets" --input - <<<"$ruleset" >/dev/null
  echo "   created ruleset"
fi

echo ">> Done. Reminder: set the secrets once per repo:"
echo "   gh secret set GALAXY_API_KEY --repo $REPO    # Galaxy import"
echo "   gh secret set AUTOMATION_TOKEN --repo $REPO  # fine-grained PAT (Contents/PRs/Issues RW)"
echo "   Without AUTOMATION_TOKEN, bot-created PRs (release-please, checksums)"
echo "   will not trigger the required CI checks."
