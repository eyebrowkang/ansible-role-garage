# ansible-role-garage

[![CI](https://github.com/eyebrowkang/ansible-role-garage/actions/workflows/ci.yml/badge.svg)](https://github.com/eyebrowkang/ansible-role-garage/actions/workflows/ci.yml)
[![Release](https://github.com/eyebrowkang/ansible-role-garage/actions/workflows/release.yml/badge.svg)](https://github.com/eyebrowkang/ansible-role-garage/actions/workflows/release.yml)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-eyebrowkang.garage-blue)](https://galaxy.ansible.com/ui/standalone/roles/eyebrowkang/garage/)

An Ansible role to install, configure, and upgrade Garage Object Storage as a systemd service on Linux systems.

## Description

This role automates the deployment of [Garage](https://garagehq.deuxfleurs.fr/), an open-source distributed object storage service. It handles:

- User and group creation
- Binary download and installation (installs only when missing; upgrades only when enabled and target > current)
- SHA256 checksum verification (with support for custom checksums)
- TOML configuration and environment file deployment
- Systemd service setup and management
- Port listening verification after service start, with optional admin API health check
- Upgrade flow with binary backup and service restart
- Automatic version comparison to skip unnecessary upgrades and prevent downgrades
- Cluster bootstrap: peer meshing via `garage node connect` (`garage_cluster_connect`) and first-layout initialization (`garage_layout_init`), both opt-in
- Cluster bootstrap configuration via `bootstrap_peers` (validated format)

## Requirements

- Ansible >= 2.16
- Target system with systemd support
- Internet access for downloading Garage binary (on target or controller when using `garage_download_local`)

## Supported Platforms

### Linux

Any Linux distribution with systemd support and python3 installed. Tested on Debian 12.

### Architectures

- x86_64
- ARM64 (aarch64)
- ARMv7l
- i386

## Role Variables

### Required Variables

| Variable                | Description                                                                                                  |
| ----------------------- | ------------------------------------------------------------------------------------------------------------ |
| `garage_rpc_secret`      | Secret key for RPC communication between nodes (alternatively set `garage_rpc_secret_file`). Generate with `openssl rand -hex 32`. |
| `garage_rpc_secret_file` | Path to a file containing the RPC secret (alternative to `garage_rpc_secret`).                            |

### Default Variables

| Variable                        | Default                                                             | Description                                                                                 |
| ------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `garage_version`                | `"v2.3.0"`                                                          | Garage version to install/upgrade to (must start with `v`)                                  |
| `garage_user`                   | `"garage"`                                                          | System user to run Garage                                                                   |
| `garage_group`                  | `"garage"`                                                          | System group for Garage                                                                     |
| `garage_home`                   | `"/var/lib/garage"`                                                 | Home directory for the Garage user                                                          |
| `garage_config_dir`             | `"/etc/garage"`                                                     | Directory for configuration files                                                           |
| `garage_data_dir`               | `"{{ garage_home }}/data"`                                          | Single data storage path                                                                    |
| `garage_data_dirs`              | `[]`                                                                | Multi-disk data directories (list of paths or `{path, capacity?, read_only?}`)              |
| `garage_metadata_dir`           | `"{{ garage_home }}/meta"`                                          | Metadata storage path                                                                       |
| `garage_db_engine`              | `"lmdb"`                                                            | Database engine (`lmdb` or `sqlite`)                                                        |
| `garage_replication_factor`     | `1`                                                                 | Data redundancy level (1 for single node; 3 recommended for production)                     |
| `garage_rpc_bind_addr`          | `"[::]:3901"`                                                       | RPC bind address                                                                            |
| `garage_rpc_public_addr`        | `"{{ ansible_default_ipv4.address \| default('127.0.0.1') }}:3901"` | RPC public address advertised to peers                                                      |
| `garage_bootstrap_peers`        | `[]`                                                                | List of peer addresses for cluster bootstrap (`<node public key>@<host>:<port>`)           |
| `garage_cluster_connect`        | `false`                                                             | Connect play hosts to each other via `garage node connect` after service start             |
| `garage_cluster_hosts`          | `[]`                                                                | Inventory hostnames forming the cluster (empty = all play hosts)                            |
| `garage_layout_init`            | `false`                                                             | Initialize the first cluster layout (version 0 → 1 only; never touches existing layouts)   |
| `garage_layout_zone`            | `""`                                                                | Zone for this node's layout role (required with `garage_layout_init`)                       |
| `garage_layout_capacity`        | `""`                                                                | Storage capacity for this node, e.g. `"1T"` (exclusive with gateway)                        |
| `garage_layout_gateway`         | `false`                                                             | Assign this node as a gateway instead of a storage node                                     |
| `garage_layout_tags`            | `[]`                                                                | Tags for this node's layout role                                                            |
| `garage_s3_region`              | `"garage"`                                                          | S3 region name                                                                              |
| `garage_s3_api_bind_addr`       | `"[::]:3900"`                                                       | S3 API bind address                                                                         |
| `garage_s3_root_domain`         | `""`                                                                | Root domain for S3 bucket access (set to enable vhost-style)                                |
| `garage_s3_web_bind_addr`       | `""`                                                                | S3 web endpoint bind address (set with root domain to enable)                               |
| `garage_s3_web_root_domain`     | `""`                                                                | Root domain for web endpoint (set with bind addr to enable)                                 |
| `garage_admin_api_bind_addr`    | `"[::]:3903"`                                                       | Admin API bind address                                                                      |
| `garage_admin_healthcheck_host` | `"127.0.0.1"`                                                       | Host used for local health checks (IPv4/IPv6)                                               |
| `garage_healthcheck_enabled`    | `false`                                                             | Enable admin API health check (port listening is always checked)                            |
| `garage_upgrade`                | `false`                                                             | Enable upgrade mode (upgrades only when target > current; prevents downgrades)              |
| `garage_upgrade_precheck`       | `true`                                                              | Run pre-upgrade status/repair checks for minor upgrades                                     |
| `garage_checksum`               | `""`                                                                | SHA256 checksum for binary verification (overrides built-in checksums)                      |
| `garage_download_url`           | `""`                                                                | Custom URL for binary download (overrides default release URL)                              |
| `garage_download_local`         | `false`                                                             | Download binary via controller then transfer via SSH (useful for air-gapped networks)       |
| `garage_config_template`        | `"garage.toml.j2"`                                                  | Path to a custom TOML config template                                                       |
| `garage_no_log`                 | `true`                                                              | Hide config/env deployment output (set `false` to see diffs while debugging)                |
| `garage_env_variables`          | `{ GARAGE_LOG_TO_JOURNALD: "1" }`                                   | Dict of environment variables for `garage.env` (set `{}` to disable the env file)           |

### Optional Variables

| Variable               | Description                       |
| ---------------------- | --------------------------------- |
| `garage_admin_token`   | Token for admin API access        |
| `garage_admin_token_file` | File path for admin API token  |
| `garage_metrics_token` | Token for metrics endpoint access |
| `garage_metrics_token_file` | File path for metrics token  |

### Notes

- `garage_rpc_secret` or `garage_rpc_secret_file` must be defined and non-empty or the role will fail validation.
- `garage_config_template` can be overridden to use a fully custom config template.
- Raw custom options are not supported; use `garage_config_template` for custom config content.
- Advanced configuration (discovery backends, performance tuning, extra APIs) should be done via a custom template.
- The environment file is rendered only when `garage_env_variables` is non-empty; by default it includes `GARAGE_LOG_TO_JOURNALD=1` (set `{}` to disable).
- When `*_file` secrets are set, they take precedence over the inline token/secret values.
- `garage_admin_token`/`garage_admin_token_file` and `garage_metrics_token`/`garage_metrics_token_file` are only rendered in the config when defined and non-empty.
- When `garage_upgrade` is `false` (default), the role only installs if the binary does not exist. When `true`, it upgrades only if the target version is newer (binary missing triggers a fresh install).
- The role supports minor upgrades only (same major version). For major upgrades, follow the official Garage upgrade guide and upgrade manually.
- Configuration and environment files are owned by `root` and the Garage group with group read access.
- The role always verifies the admin API port is listening after service start. When `garage_healthcheck_enabled: true`, it additionally checks the `/health` endpoint. On recent Garage versions (>= v2.2) `/health` returns 503 until a cluster layout is configured; the check runs after the cluster connect / layout init steps, so it can be enabled together with `garage_layout_init` even on a fresh install.
- `garage_download_url` and `garage_download_local` apply to both installs and upgrades.
- If the requested version is not in the built-in checksums and `garage_checksum` is empty, the download skips checksum verification. Set `garage_checksum` for custom versions.
- Set `garage_data_dirs` for multi-disk; it takes precedence over `garage_data_dir`. Entries can be simple paths or maps; set `read_only: true` explicitly for read-only disks (and omit `capacity` when read-only).

## Dependencies

None.

## Examples

### Minimal - Fresh Install

```yaml
- name: Install Garage
  hosts: storage
  become: true
  vars:
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
  roles:
    - eyebrowkang.garage
```

### Cluster Deployment

The role can bootstrap a complete cluster: `garage_cluster_connect` meshes the
play hosts via `garage node connect` (Garage persists known peers, so this is a
one-time bootstrap), and `garage_layout_init` then applies the **first** cluster
layout. Both are disabled by default.

```yaml
- name: Deploy Garage Cluster
  hosts: storage_nodes
  become: true
  vars:
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
    garage_replication_factor: 3
    garage_rpc_public_addr: "{{ ansible_host }}:3901"
    garage_cluster_connect: true
    garage_layout_init: true
    garage_layout_zone: dc1
    garage_layout_capacity: "1T"
  roles:
    - eyebrowkang.garage
```

Notes:

- The order is connect → layout: `garage layout assign` only accepts node IDs
  the cluster already knows, so nodes must be connected first.
- `garage_layout_init` acts **only when no layout exists** (layout version
  0 → 1). Capacity changes, adding/removing nodes and rebalancing afterwards
  are operator actions — the role never modifies an existing layout.
- Zone, capacity, gateway and tags are per-node values: set them in
  `host_vars` for heterogeneous clusters (e.g. different capacities or a
  gateway-only node with `garage_layout_gateway: true`).
- All cluster nodes must be in the same play (`garage_cluster_hosts` defaults
  to the play hosts).
- Alternatively, `garage_bootstrap_peers` accepts pre-known identifiers in the
  `<node public key>@<host>:<port>` format — bare `host:port` entries are
  silently ignored by Garage, and the role rejects them at validation time.

### Multiple Data Directories

```yaml
- name: Install Garage with multiple data disks
  hosts: storage
  become: true
  vars:
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
    garage_data_dirs:
      - path: "/mnt/garage-d1"
        capacity: "2T"
      - path: "/mnt/garage-d2"
        capacity: "2T"
  roles:
    - eyebrowkang.garage
```

### Additional Options and Environment Variables

```yaml
- name: Install Garage with extra config options
  hosts: storage
  become: true
  vars:
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
    garage_admin_token: "{{ vault_garage_admin_token }}"
    garage_metrics_token: "{{ vault_garage_metrics_token }}"
    garage_s3_root_domain: ".s3.example.com"
    garage_s3_web_bind_addr: "[::]:3902"
    garage_s3_web_root_domain: ".web.example.com"
    garage_env_variables:
      GARAGE_LOG_LEVEL: "info"
  roles:
    - eyebrowkang.garage
```

### Upgrade

```yaml
- name: Upgrade Garage
  hosts: storage
  become: true
  vars:
    garage_version: "v2.3.0"
    garage_upgrade: true
    garage_upgrade_precheck: true
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
  roles:
    - eyebrowkang.garage
```

### Rolling Upgrade (cluster)

Upgrade one node at a time with `serial: 1`; the pre-upgrade checks
(`garage status` / `repair`) run against the live cluster before each node is
taken down, and the port/health checks gate progression to the next node:

```yaml
- name: Rolling upgrade
  hosts: storage_nodes
  become: true
  serial: 1
  vars:
    garage_version: "v2.3.0"
    garage_upgrade: true
    garage_healthcheck_enabled: true
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
  roles:
    - eyebrowkang.garage
```

The cluster layout is never touched during upgrades.

### Vault Usage

Store secrets securely with ansible-vault:

```bash
# Create an encrypted vault file
ansible-vault create group_vars/storage/vault.yml
```

```yaml
# group_vars/storage/vault.yml
vault_garage_rpc_secret: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
vault_garage_admin_token: "your-admin-token-here"
vault_garage_metrics_token: "your-metrics-token-here"
```

Generate secrets:

```bash
openssl rand -hex 32
```

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development environment, test
matrix (molecule + vagrant locally, containers in CI), conventional-commit PR
titles, and the release-please based release flow.

## License

MIT
