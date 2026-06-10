#!/usr/bin/env bash
# Fetch SHA256 checksums for a Garage release (all four architectures) and
# append them to vars/main.yml. If the release shares the major version of the
# current default and is newer, also bump the default garage_version.
#
# Usage: update-checksums.sh [vX.Y.Z]   (no argument = latest stable release)
#
# Checksums are computed by downloading each binary from the official release
# endpoint — the same artifacts the role installs. Writes the version handled
# to /tmp/garage_new_version (consumed by the GitHub workflow). Exits 0 with
# no file changes when the version is already present.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VARS_FILE="${VARS_FILE:-$REPO_ROOT/vars/main.yml}"
DEFAULTS_FILE="${DEFAULTS_FILE:-$REPO_ROOT/defaults/main.yml}"
README_FILE="${README_FILE:-$REPO_ROOT/README.md}"
ARGSPEC_FILE="${ARGSPEC_FILE:-$REPO_ROOT/meta/argument_specs.yml}"

RELEASES_API="https://git.deuxfleurs.fr/api/v1/repos/Deuxfleurs/garage/releases"
DOWNLOAD_BASE="https://garagehq.deuxfleurs.fr/_releases"
# Order matches the existing blocks in vars/main.yml.
ARCHES=(
  x86_64-unknown-linux-musl
  aarch64-unknown-linux-musl
  armv6l-unknown-linux-musleabihf
  i686-unknown-linux-musl
)

version="${1:-}"
if [[ -z "$version" ]]; then
  # Garage maintains parallel release lines (e.g. v1.3.1 next to v2.2.0), so
  # "newest by date" is wrong — pick the highest stable semver tag instead.
  version=$(curl -fsSL "$RELEASES_API?limit=30" \
    | python3 -c 'import json,sys; print("\n".join(r["tag_name"] for r in json.load(sys.stdin) if not r["prerelease"] and not r["draft"]))' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
fi

if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: invalid version '$version' (expected vX.Y.Z)" >&2
  exit 1
fi
printf '%s' "$version" > /tmp/garage_new_version

if grep -q "^  ${version}:" "$VARS_FILE"; then
  echo "Checksums for $version already present in $VARS_FILE — nothing to do."
  exit 0
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

declare -A sums
for arch in "${ARCHES[@]}"; do
  url="$DOWNLOAD_BASE/$version/$arch/garage"
  echo "Downloading $url"
  curl -fSL --retry 3 --max-time 900 -o "$tmpdir/garage" "$url"
  sums[$arch]=$(sha256sum "$tmpdir/garage" | awk '{print $1}')
  echo "  $arch: ${sums[$arch]}"
done

{
  echo "  ${version}:"
  for arch in "${ARCHES[@]}"; do
    echo "    ${arch}: \"${sums[$arch]}\""
  done
} >> "$VARS_FILE"
echo "Appended $version checksums to $VARS_FILE"

current_default=$(grep -oP '^garage_version: "\Kv[0-9]+\.[0-9]+\.[0-9]+' "$DEFAULTS_FILE")
cur_major=${current_default#v}; cur_major=${cur_major%%.*}
new_major=${version#v}; new_major=${new_major%%.*}
highest=$(printf '%s\n%s\n' "$current_default" "$version" | sort -V | tail -1)

if [[ "$new_major" == "$cur_major" && "$highest" == "$version" && "$version" != "$current_default" ]]; then
  sed -i "s/^garage_version: \"$current_default\"/garage_version: \"$version\"/" "$DEFAULTS_FILE"
  sed -i "s/default: \"$current_default\"/default: \"$version\"/" "$ARGSPEC_FILE"
  sed -i "s/\`\"$current_default\"\`/\`\"$version\"\`/" "$README_FILE"
  sed -i "s/garage_version: \"$current_default\"/garage_version: \"$version\"/" "$README_FILE"
  echo "Bumped default garage_version: $current_default -> $version"
else
  echo "Default garage_version ($current_default) left unchanged (new major or not newer)."
fi
