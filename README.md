# ansible-role-garage

An Ansible role to install, configure, and upgrade Garage Object Store as a systemd service on Linux systems.

## Description

This role automates the deployment of [Garage](https://garagehq.deuxfleurs.fr/), an open-source distributed object storage service. It handles:

- User and group creation
- Binary download and installation (installs only when missing; upgrades only when enabled and target > current)
- SHA256 checksum verification (with support for custom checksums)
- TOML configuration and environment file deployment
- Systemd service setup and management
- Health check verification via admin API
- Upgrade flow with binary backup and service restart
- Automatic version comparison to skip unnecessary upgrades and prevent downgrades
- Cluster bootstrap configuration via `bootstrap_peers`

## Requirements

- Ansible >= 2.16
- Target system with systemd support
- Internet access for downloading Garage binary

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
| `garage_version`                | `"v2.0.0"`                                                          | Garage version to install/upgrade to (must start with `v`)                                  |
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
| `garage_bootstrap_peers`        | `[]`                                                                | List of peer addresses for cluster bootstrap                                                |
| `garage_s3_region`              | `"garage"`                                                          | S3 region name                                                                              |
| `garage_s3_api_bind_addr`       | `"[::]:3900"`                                                       | S3 API bind address                                                                         |
| `garage_s3_root_domain`         | `""`                                                                | Root domain for S3 bucket access (set to enable vhost-style)                                |
| `garage_s3_web_bind_addr`       | `""`                                                                | S3 web endpoint bind address (set with root domain to enable)                               |
| `garage_s3_web_root_domain`     | `""`                                                                | Root domain for web endpoint (set with bind addr to enable)                                 |
| `garage_admin_api_bind_addr`    | `"[::]:3903"`                                                       | Admin API bind address                                                                      |
| `garage_admin_healthcheck_host` | `"127.0.0.1"`                                                       | Host used for local health checks (IPv4/IPv6)                                               |
| `garage_upgrade`                | `false`                                                             | Enable upgrade mode (upgrades only when target > current; prevents downgrades)              |
| `garage_upgrade_precheck`       | `true`                                                              | Run pre-upgrade status/repair checks for minor upgrades                                     |
| `garage_checksum`               | `""`                                                                | SHA256 checksum for binary verification (overrides built-in checksums)                      |
| `garage_config_template`        | `"garage.toml.j2"`                                                  | Path to a custom TOML config template                                                       |
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
- Set `garage_data_dirs` for multi-disk; it takes precedence over `garage_data_dir`. Entries can be simple paths or maps; use `capacity` for writable disks and omit it for `read_only` entries.

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

### Cluster with Bootstrap Peers

```yaml
- name: Deploy Garage Cluster
  hosts: storage_nodes
  become: true
  vars:
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
    garage_replication_factor: 3
    garage_rpc_public_addr: "{{ ansible_host }}:3901"
    garage_bootstrap_peers: >-
      {{ groups['storage_nodes'] | map('extract', hostvars, 'ansible_host')
         | map('regex_replace', '^(.*)$', '\1:3901') | list }}
  roles:
    - eyebrowkang.garage
```

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
    garage_version: "v2.1.0"
    garage_upgrade: true
    garage_upgrade_precheck: true
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
  roles:
    - eyebrowkang.garage
```

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

## License

MIT
