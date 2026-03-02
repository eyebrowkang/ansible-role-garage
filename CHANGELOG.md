# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[1.1.0]: https://github.com/eyebrowkang/ansible-role-garage/releases/tag/v1.1.0
[1.0.0]: https://github.com/eyebrowkang/ansible-role-garage/releases/tag/v1.0.0
