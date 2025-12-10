# Ansible Role: Garage

Installs and configures [Garage](https://garagehq.deuxfleurs.fr/), an open-source distributed object storage service.

## Requirements

- Ansible 2.11+
- Systemd-based Linux distribution (Debian, Ubuntu, CentOS, etc.)

## Security Notice

For production deployments, you **MUST** customize the following secrets (use `openssl rand -hex 32` to generate):

- `garage_rpc_secret`: Secret key for RPC communication between nodes
- `garage_metrics_token`: Token for accessing metrics endpoint
- `garage_admin_token`: Token for admin API access

You should also customize the following domains:

- `garage_s3_root_domain`: Root domain for S3 bucket access
- `garage_web_root_domain`: Root domain for web endpoint

**Store these secrets in Ansible Vault for security.**

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

### General

| Variable | Default | Description |
|----------|---------|-------------|
| `garage_version` | `"v2.0.0"` | Version of Garage to install |
| `garage_upgrade` | `true` | Whether to upgrade when version mismatch is detected |
| `garage_bin_path` | `"/usr/local/bin/garage"` | Path to install the binary |
| `garage_config_dir` | `"/etc/garage"` | Path for configuration |

### Daemon

| Variable | Default | Description |
|----------|---------|-------------|
| `garage_daemon_user` | `"garage"` | User to run Garage |
| `garage_daemon_group` | `"garage"` | Group for Garage |

### Custom Templates

You can provide your own configuration templates by setting the following variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `garage_config_template` | `""` | Path to custom garage.toml template |
| `garage_service_template` | `""` | Path to custom systemd service template |

Example usage:

```yaml
garage_config_template: "{{ playbook_dir }}/templates/my-garage.toml.j2"
garage_service_template: "{{ playbook_dir }}/templates/my-garage.service.j2"
```

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `garage_db_engine` | `"lmdb"` | Database engine (`sqlite` or `lmdb`) |
| `garage_replication_factor` | `1` | Data redundancy level |
| `garage_rpc_bind_addr` | `"[::]:3901"` | RPC bind address |
| `garage_rpc_public_addr` | `"127.0.0.1:3901"` | RPC public address |
| `garage_rpc_secret` | (placeholder) | **Required:** Secret key for RPC communication |

### S3 API

| Variable | Default | Description |
|----------|---------|-------------|
| `garage_s3_region` | `"garage"` | S3 region name |
| `garage_s3_api_bind_addr` | `"[::]:3900"` | S3 API bind address |
| `garage_s3_root_domain` | `".s3.garage.local"` | **Required:** Root domain for S3 buckets |

### S3 Web

| Variable | Default | Description |
|----------|---------|-------------|
| `garage_web_bind_addr` | `"[::]:3902"` | Web endpoint bind address |
| `garage_web_root_domain` | `".web.garage.local"` | **Required:** Root domain for web endpoint |

### Admin API

| Variable | Default | Description |
|----------|---------|-------------|
| `garage_admin_api_bind_addr` | `"[::]:3903"` | Admin API bind address |
| `garage_metrics_token` | (placeholder) | **Required:** Token for metrics access |
| `garage_metrics_require_token` | `true` | Whether to require token for metrics |
| `garage_admin_token` | (placeholder) | **Required:** Token for admin API access |

## Minimal Secure Playbook

Below is a minimal playbook example for a secure production deployment:

### Directory Structure

```
my-garage-deployment/
├── inventory.yml
├── playbook.yml
├── group_vars/
│   └── storage_nodes/
│       └── vault.yml      # Encrypted with ansible-vault
```

### playbook.yml

```yaml
---
- name: Deploy Garage Storage
  hosts: storage_nodes
  become: true
  roles:
    - role: eyebrowkang.garage
      vars:
        # Domains (customize for your environment)
        garage_s3_root_domain: ".s3.example.com"
        garage_web_root_domain: ".web.example.com"

        # Secrets (from vault)
        garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
        garage_metrics_token: "{{ vault_garage_metrics_token }}"
        garage_admin_token: "{{ vault_garage_admin_token }}"

        # Optional: RPC public address for multi-node setup
        garage_rpc_public_addr: "{{ ansible_host }}:3901"
```

### group_vars/storage_nodes/vault.yml

Create this file and encrypt it with `ansible-vault encrypt group_vars/storage_nodes/vault.yml`:

```yaml
---
# Generate with: openssl rand -hex 32
vault_garage_rpc_secret: "your-64-char-hex-secret-here"
vault_garage_metrics_token: "your-64-char-hex-token-here"
vault_garage_admin_token: "your-64-char-hex-token-here"
```

### inventory.yml

```yaml
---
all:
  children:
    storage_nodes:
      hosts:
        node1:
          ansible_host: 192.168.1.10
        node2:
          ansible_host: 192.168.1.11
        node3:
          ansible_host: 192.168.1.12
```

### Running the Playbook

```bash
# Generate secrets
openssl rand -hex 32  # Run 3 times for each secret

# Create and edit vault file
ansible-vault create group_vars/storage_nodes/vault.yml

# Run playbook
ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass
```

## Version Management

The role intelligently handles binary installation:

1. **Check existence**: Verifies if Garage binary exists at `garage_bin_path`
2. **Version comparison**: Compares installed version with `garage_version`
3. **Upgrade control**: Respects `garage_upgrade` variable:
   - `true` (default): Automatically upgrade/downgrade to match `garage_version`
   - `false`: Skip installation if any version is already installed

Example to pin version and prevent upgrades:

```yaml
garage_version: "v2.0.0"
garage_upgrade: false
```

## License

MIT
