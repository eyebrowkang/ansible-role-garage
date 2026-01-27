# ansible-role-garage

An Ansible role to install, configure, and upgrade Garage Object Store as a systemd service on Linux systems.

## Description

This role automates the deployment of [Garage](https://garagehq.deuxfleurs.fr/), an open-source distributed object storage service. It handles:

- User and group creation
- Binary download and installation (fresh install only, no version-based overwrite)
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

| Variable           | Description                                                              |
| ------------------ | ------------------------------------------------------------------------ |
| `garage_rpc_secret` | Secret key for RPC communication between nodes. Generate with `openssl rand -hex 32`. |

### Default Variables

| Variable                      | Default                                                          | Description                                                                   |
| ----------------------------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `garage_version`              | `"v2.0.0"`                                                       | Garage version to install/upgrade to (must start with `v`)                    |
| `garage_user`                 | `"garage"`                                                        | System user to run Garage                                                     |
| `garage_group`                | `"garage"`                                                        | System group for Garage                                                       |
| `garage_home`                 | `"/var/lib/garage"`                                               | Home directory for the Garage user                                            |
| `garage_config_dir`           | `"/etc/garage"`                                                   | Directory for configuration files                                             |
| `garage_data_dir`             | `"{{ garage_home }}/data"`                                        | Data storage path                                                             |
| `garage_metadata_dir`         | `"{{ garage_home }}/meta"`                                        | Metadata storage path                                                         |
| `garage_db_engine`            | `"lmdb"`                                                          | Database engine (`lmdb` or `sqlite`)                                          |
| `garage_replication_factor`   | `1`                                                               | Data redundancy level (must be a positive integer)                            |
| `garage_rpc_bind_addr`        | `"[::]:3901"`                                                     | RPC bind address                                                              |
| `garage_rpc_public_addr`      | `"{{ ansible_default_ipv4.address \| default('127.0.0.1') }}:3901"` | RPC public address advertised to peers                                        |
| `garage_bootstrap_peers`      | `[]`                                                              | List of peer addresses for cluster bootstrap                                  |
| `garage_s3_region`            | `"garage"`                                                        | S3 region name                                                                |
| `garage_s3_api_bind_addr`     | `"[::]:3900"`                                                     | S3 API bind address                                                           |
| `garage_s3_root_domain`       | `".s3.garage.local"`                                              | Root domain for S3 bucket access                                              |
| `garage_s3_web_bind_addr`     | `"[::]:3902"`                                                     | S3 web endpoint bind address                                                  |
| `garage_s3_web_root_domain`   | `".web.garage.local"`                                             | Root domain for web endpoint                                                  |
| `garage_admin_api_bind_addr`  | `"[::]:3903"`                                                     | Admin API bind address                                                        |
| `garage_upgrade`              | `false`                                                           | Enable upgrade mode (compares versions, prevents downgrades)                  |
| `garage_checksum`             | `""`                                                              | SHA256 checksum for binary verification (overrides built-in checksums)        |
| `garage_config_template`      | `"garage.toml.j2"`                                                | Path to a custom TOML config template                                         |
| `garage_config_custom_options`| `""`                                                              | Raw TOML lines appended to the generated config file (default template only)  |
| `garage_env_variables`        | `{}`                                                              | Dict of environment variables for the env file (created when non-empty, removed when empty) |

### Optional Variables

| Variable              | Description                                           |
| --------------------- | ----------------------------------------------------- |
| `garage_admin_token`  | Token for admin API access                            |
| `garage_metrics_token`| Token for metrics endpoint access                     |

### Notes

- `garage_rpc_secret` must be defined and non-empty or the role will fail validation.
- `garage_config_custom_options` and `garage_config_template` are mutually exclusive; if both are set, the template takes precedence and custom options are ignored.
- The environment file is rendered only when `garage_env_variables` is non-empty and removed otherwise.
- `garage_admin_token` and `garage_metrics_token` are only rendered in the config when defined and non-empty.
- When `garage_upgrade` is `false` (default), the role only installs if the binary does not exist. Set to `true` to enable version comparison and upgrade.

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

### Custom Options and Environment Variables

```yaml
- name: Install Garage with custom config
  hosts: storage
  become: true
  vars:
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
    garage_admin_token: "{{ vault_garage_admin_token }}"
    garage_metrics_token: "{{ vault_garage_metrics_token }}"
    garage_config_custom_options: |
      [s3_api]
      max_concurrent_requests = 128
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
