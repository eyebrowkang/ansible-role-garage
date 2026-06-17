# Contributing / Development

## Environment

Tooling is managed with [uv](https://docs.astral.sh/uv/); common tasks are
wrapped in the [Makefile](Makefile):

```bash
uv sync                  # dev toolchain (docker scenario)
uv sync --group vagrant  # add the vagrant/libvirt track

make lint        # yamllint + ansible-lint
make test        # molecule test — docker scenario (fast; what CI runs)
make converge    # converge the docker instance, keep it for debugging
make destroy     # tear it down
make test-vm     # molecule test — vagrant scenario (needs libvirt + KVM)
```

The extra vagrant scenarios (`multidisk` / `negative` / `upgrade` / `cluster`)
need the same molecule-plugins#301 env that `make test-vm` exports; run them
with that env and `-s <scenario>`:

```bash
ANSIBLE_LIBRARY="$(uv run python -c 'import os, molecule_plugins.vagrant as m; print(os.path.join(os.path.dirname(m.__file__), "modules"))')" \
ANSIBLE_FILTER_PLUGINS="$(uv run python -c 'import os, molecule as m; print(os.path.join(os.path.dirname(m.__file__), "provisioner", "ansible", "plugins", "filter"))')" \
uv run molecule test -s cluster   # or multidisk / negative / upgrade
```

Optional pre-commit hooks: `uv sync && uvx pre-commit install` (config in
`.pre-commit-config.yaml`). This role is managed with
[copier](https://copier.readthedocs.io/); pull template improvements with
`copier update --trust`.

## Test scenarios

| Scenario    | Driver          | Purpose                                              |
| ----------- | --------------- | --------------------------------------------------- |
| `default`   | docker          | What CI runs: debian12 / ubuntu2404 / rockylinux9 (`MOLECULE_DISTRO` matrix) |
| `vagrant`   | vagrant/libvirt | Fresh install + idempotence + verify                |
| `multidisk` | vagrant/libvirt | `garage_data_dirs` multi-disk layout                |
| `negative`  | vagrant/libvirt | Validation failure-path assertions (bad input)      |
| `upgrade`   | vagrant/libvirt | v2.0.0 → v2.1.0 minor upgrade; S3 object survives    |
| `cluster`   | vagrant/libvirt | 3-node mesh via `garage node connect` + layout      |

Only the docker `default` scenario runs in GitHub CI (no KVM on public
runners); the vagrant scenarios are local-only.

## Workflow

- `main` is locked: changes land via PR, required checks must pass
  (`lint`, `molecule-docker (debian12/ubuntu2404/rockylinux9)`, `pr-title`).
- PRs are **squash-merged** and the **PR title becomes the commit message**,
  so it must follow [Conventional Commits](https://www.conventionalcommits.org/):
  `feat:` (minor bump), `fix:` (patch), `feat!:`/`BREAKING CHANGE` (major),
  plus `docs:` / `test:` / `refactor:` / `chore:` / `ci:` (no release).
  Individual commits inside a PR can be messy — only the title matters.

## Releases

[release-please](https://github.com/googleapis/release-please) maintains a
release PR from the conventional commit history (version bump + CHANGELOG).
**Merging that PR is the entire release process**: it tags `vX.Y.Z`, creates
the GitHub release, and the same workflow imports the role into Ansible
Galaxy (`GALAXY_API_KEY` repo secret).

### Required secrets

| Secret             | Purpose                                                          |
| ------------------ | ---------------------------------------------------------------- |
| `GALAXY_API_KEY`   | Galaxy import on release                                          |
| `AUTOMATION_TOKEN` | Fine-grained PAT (Contents, Pull requests, Issues — read/write). PRs created with the default `GITHUB_TOKEN` never trigger `pull_request` workflows, so without this token the release-please and checksum PRs would sit forever without their required CI checks. |

## Checksum updates

A weekly workflow (`update-checksums.yml`) checks for new Garage releases,
downloads all four architecture binaries, and opens a `feat:` PR with the
SHA256 checksums (bumping the default `garage_version` when the major version
matches). CI installs the new version in the molecule matrix, so merging the
PR is a verified upgrade. Manual run: `./scripts/update-checksums.sh [vX.Y.Z]`.

## Repository setup (maintainers)

One-time repo governance — branch protection, squash-only merges, Actions
token, required checks — is applied with the scaffold's `scripts/setup-repo.sh`,
run after the first CI run (from a checkout of the `ansible-development`
scaffold):

```bash
scripts/setup-repo.sh eyebrowkang/ansible-role-garage \
  "lint,molecule-docker (debian12),molecule-docker (ubuntu2404),molecule-docker (rockylinux9),pr-title"
```

Then set the `GALAXY_API_KEY` and `AUTOMATION_TOKEN` secrets (see above).
