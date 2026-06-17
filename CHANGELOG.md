# Changelog

## [1.3.1](https://github.com/eyebrowkang/ansible-role-garage/compare/v1.3.0...v1.3.1) (2026-06-17)


### Bug Fixes

* destroy recorded molecule instances ([#14](https://github.com/eyebrowkang/ansible-role-garage/issues/14)) ([0afc113](https://github.com/eyebrowkang/ansible-role-garage/commit/0afc113dde77b453e56aa594cbf9a403cef00e75))

## [1.3.0](https://github.com/eyebrowkang/ansible-role-garage/compare/v1.2.0...v1.3.0) (2026-06-10)


### Features

* cluster connect and first-layout initialization ([#9](https://github.com/eyebrowkang/ansible-role-garage/issues/9)) ([e330045](https://github.com/eyebrowkang/ansible-role-garage/commit/e3300452b6ffd97351eba58739529bee445b1fc3))

## [1.2.0] - 2026-06-10

### Added

- `garage_download_url` to install from a custom or mirror URL, and
  `garage_download_local` to download via the controller and transfer over SSH
  (useful for air-gapped networks).
- SHA256 checksums for Garage v2.3.0.
- Validation of `garage_bootstrap_peers` entry format
  (`<node public key>@<host>:<port>`); bare `host:port` entries are silently
  ignored by Garage and now fail fast with guidance.
- Support for `i686` and `armv6l` values of `ansible_architecture`.

### Changed

- Default `garage_version` bumped from v2.0.0 to v2.3.0 (the default
  `GARAGE_LOG_TO_JOURNALD=1` only takes effect on official builds >= v2.2.0).
- Install and upgrade now share a single download task file; upgrades honor
  `garage_download_url` and `garage_download_local` (previously hardcoded to
  the official release URL).
- Unsupported architectures now fail with a clear message instead of silently
  downloading the x86_64 binary (set `garage_download_url` for custom builds).
- Handlers are flushed before the service start task, so fresh installs and
  upgrades result in a single service start instead of start-then-restart.
- Cluster molecule scenario bootstraps the mesh via `garage node connect` and
  verifies three healthy cluster members (previously nodes never joined).
- Removed dead `provisioner.lint` keys from molecule configs (ignored since
  Molecule v6).

### Fixed

- Upgrade flow ignored the custom download options, breaking custom-URL and
  air-gapped upgrade paths.
- Misleading "major version upgrade detected" error when the installed binary's
  version output could not be parsed; the role now fails with a clear parse
  error instead.
- README cluster example used bare `host:port` bootstrap peers, which Garage
  silently ignores — rewritten to the two-phase `node connect` pattern.
- README claimed `/health` returns 502 on fresh installs; actual behavior is
  200 on v2.0 and 503 on >= v2.2 until a layout is configured.
- `meta/argument_specs.yml` was missing `garage_download_url` and
  `garage_download_local`.

## [1.1.0] - 2026-03-02

### Added

- Role argument specs for input validation (`meta/argument_specs.yml`).
- Version parsing verification in upgrade molecule scenario.

### Changed

- Improved upgrade flow with better version check logic and service template handling.
- Adjusted service health-check defaults and verification flow.

### Fixed

- Fixed changelog link for v1.0.0.

## [1.0.0] - 2026-01-29

### Added

- Initial release of the Ansible role for Garage Object Store with systemd service management.
- Binary install and upgrade workflow with checksum verification and downgrade/major-upgrade safeguards.
- Config templating for Garage (RPC/S3/admin), optional env file rendering, and systemd unit hardening.
- Multi-disk data directory support with ReadWritePaths wiring.
- Optional admin API health check after service start (enabled by default).

[1.2.0]: https://github.com/eyebrowkang/ansible-role-garage/releases/tag/v1.2.0
[1.1.0]: https://github.com/eyebrowkang/ansible-role-garage/releases/tag/v1.1.0
[1.0.0]: https://github.com/eyebrowkang/ansible-role-garage/releases/tag/v1.0.0
