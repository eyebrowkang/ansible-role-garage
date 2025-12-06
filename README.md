# Ansible Role: Garage

Installs and configures [Garage](https://garagehq.deuxfleurs.fr/), an open-source distributed object storage service.

## Requirements

- Ansible 2.9+
- Systemd-based Linux distribution (Debian, Ubuntu, CentOS, etc.)

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

### General

- `garage_version`: Version of Garage to install (default: "v2.0.0")
- `garage_bin_path`: Path to install the binary (default: "/usr/local/bin/garage")
- `garage_config_dir`: Path for configuration (default: "/etc/garage")

### Daemon

- `garage_daemon_user`: User to run Garage (default: "garage")
- `garage_daemon_group`: Group for Garage (default: "garage")

### Configuration

- `garage_db_engine`: Database engine, e.g., `sqlite` or `lmdb` (default: "lmdb")
- `garage_replication_factor`: Data redundancy level (default: 1)
- `garage_rpc_bind_addr`: RPC bind address (default: "[::]:3901")
- `garage_rpc_secret`: Secret key for RPC communication. **Important:** Change this in production!

### S3 API

- `garage_s3_region`: S3 region name (default: "garage")
- `garage_s3_root_domain`: Root domain for S3 buckets (default: ".s3.garage.localhost")

## Example Playbook

```yaml
- hosts: storage_nodes
  become: true
  roles:
    - role: ansible-role-garage
      vars:
        garage_rpc_secret: "0123456789abcdef0123456789abcdef"
        garage_s3_root_domain: ".s3.garage.local"
        garage_web_root_domain: ".web.garage.local"
        garage_metrics_token: "0123456789abcdef0123456789abcdef"
        garage_admin_token: "0123456789abcdef0123456789abcdef"
```
