# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Breaking Changes

- Renamed `garage_daemon_user` to `garage_user`
- Renamed `garage_daemon_group` to `garage_group`
- Renamed `garage_web_bind_addr` to `garage_s3_web_bind_addr`
- Renamed `garage_web_root_domain` to `garage_s3_web_root_domain`
- Moved `garage_bin_path` to internal `vars/main.yml` as `garage_binary_path`
- Changed `garage_env_vars` (string) to `garage_env_variables` (dict)
- Changed `garage_upgrade` default from `true` to `false`
- Changed `garage_rpc_secret` default from placeholder to empty string (now validated as required)
- Changed `garage_config_template` default from `""` to `"garage.toml.j2"`
- `garage_admin_token` and `garage_metrics_token` are now optional (commented out by default, rendered conditionally)
- Removed `garage_service_template` variable
- Removed `garage_metrics_require_token` variable
- Added strict validation that can fail previously accepted inputs (version format, rpc_secret required, replication_factor positive integer)
- Version comparison now prevents downgrades when `garage_upgrade` is `true`

### Added

- `garage_home` variable for base home directory (`/var/lib/garage`)
- `garage_bootstrap_peers` list for cluster bootstrap configuration
- `garage_checksum` variable for SHA256 checksum override
- `garage_config_custom_options` for appending raw TOML lines to the default config template
- `garage_env_variables` dict for variable-driven environment file generation
- `garage_admin_healthcheck_host` variable to control health check host (IPv4/IPv6)
- `vars/main.yml` with internal `garage_binary_path` and `_garage_known_checksums`
- `tasks/validate.yml` with input validation (version format, rpc_secret, replication_factor, upgrade boolean)
- `tasks/setup.yml` for system user/group and directory creation
- `tasks/version_check.yml` for upgrade version comparison with downgrade prevention
- `tasks/upgrade.yml` for upgrade flow (stop, backup, download, restart)
- `tasks/service.yml` with service start, handler flush, port wait, and health check
- Health check via `GET /health` on admin API endpoint
- Systemd security hardening: `PrivateTmp`, `ProtectSystem=strict`, `ReadWritePaths`
- Systemd `Documentation=`, `Type=simple`, `WorkingDirectory=`, `Restart=on-failure`, `RestartSec=5`, `TimeoutStopSec=30`
- `# Managed by Ansible` header and docs URL in config template
- Conditional rendering of `bootstrap_peers`, `admin_token`, `metrics_token` in config
- Download retries (3 attempts with 10-second delay)
- `.ansible-lint`, `.editorconfig`, `.yamllint.yml`, `.gitignore` configuration files
- Molecule cluster scenario with 3-node bootstrap_peers test
- Molecule upgrade scenario with prepare stage (v2.0.0 -> v2.1.0)
- CHANGELOG.md

### Changed

- Restructured `tasks/main.yml` to orchestrate via `include_tasks`: validate, setup, version_check, upgrade/install, configure, service
- `garage_rpc_public_addr` now defaults to `{{ ansible_default_ipv4.address }}:3901` instead of `127.0.0.1:3901`
- User created with `create_home: true`, `shell: /sbin/nologin` (was `create_home: false`, `shell: /bin/false`)
- Install `acl` package (required for `become_user`)
- Split handlers into separate "Reload systemd" and "Restart garage"
- Systemd unit now notifies both handlers on change
- Environment file deployed/removed based on `garage_env_variables` dict (non-empty creates, empty removes)
- Config directory now root-owned with group read access; config/env files owned by root with group read
- Environment variable values now JSON-quoted to avoid parsing issues
- Health check now derives port and uses configurable host (supports IPv6 bracket handling)
- Added validation to ensure `garage_admin_api_bind_addr` includes a port
- Molecule default scenario: single Debian 12 VM with 1024 MB, uses `roles:` syntax
- Minimum Ansible version bumped to 2.16
- Expanded supported platforms: ArchLinux, Debian, Ubuntu, EL (8/9/10), Fedora, opensuse
- Rewrote README with variable reference table and example playbooks

### Removed

- `garage_service_template` variable (no longer customizable)
- `garage_metrics_require_token` variable
- Insecure placeholder defaults for `garage_rpc_secret`, `garage_metrics_token`, `garage_admin_token`
- `version` field from `meta/main.yml`

## [0.1.1] - 2025-09-04

### Added

- Initial release of ansible-role-garage
- Install and configure Garage Object Store as a systemd service
- Configurable installation with default Garage v2.0.0

[Unreleased]: https://github.com/eyebrowkang/ansible-role-garage/compare/0.1.1...HEAD
[0.1.1]: https://github.com/eyebrowkang/ansible-role-garage/releases/tag/0.1.1
