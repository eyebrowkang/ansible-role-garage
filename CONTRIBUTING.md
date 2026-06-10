# Contributing / Development

## Environment

Local development uses the `ansible-dev` conda environment with molecule +
vagrant (libvirt). CI tooling versions are pinned in `requirements-ci.txt`.
Common commands are wrapped in the [justfile](justfile):

```bash
just lint              # yamllint + ansible-lint
just test              # molecule test -s default (vagrant/libvirt)
just test cluster      # any scenario: default / multidisk / upgrade / cluster
just ci-test           # container-based CI scenario locally (docker)
just ci-test rockylinux9
just converge          # converge + keep the VM for debugging
just update-checksums  # fetch checksums for the latest Garage release
```

Optional pre-commit hooks: `pre-commit install` (config in
`.pre-commit-config.yaml`).

## Test scenarios

| Scenario    | Driver          | Purpose                                      |
| ----------- | --------------- | -------------------------------------------- |
| `default`   | vagrant/libvirt | Fresh install + idempotence + verify          |
| `multidisk` | vagrant/libvirt | `garage_data_dirs` multi-disk layout          |
| `upgrade`   | vagrant/libvirt | v2.0.0 → v2.1.0 minor upgrade with layout     |
| `cluster`   | vagrant/libvirt | 3-node mesh via `garage node connect`         |
| `ci`        | docker          | What CI runs: debian12 / ubuntu2404 / rockylinux9 |

## Workflow

- `main` is locked: changes land via PR, required checks must pass
  (`lint`, `molecule (…)`, `pr-title`).
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

## Checksum updates

A weekly workflow (`update-checksums.yml`) checks for new Garage releases,
downloads all four architecture binaries, and opens a `feat:` PR with the
SHA256 checksums (bumping the default `garage_version` when the major version
matches). CI installs the new version in the molecule matrix, so merging the
PR is a verified upgrade. Manual run: `just update-checksums [vX.Y.Z]`.
