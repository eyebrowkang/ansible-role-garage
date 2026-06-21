# Examples

Playbook examples for the `eyebrowkang.garage` role. For the full variable
reference and notes, see [README.md](README.md). For a minimal fresh-install
example, see the [Examples](README.md#examples) section there.

## Cluster Deployment

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

## Multiple Data Directories

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

## Additional Options and Environment Variables

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

## Upgrade

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

## Rolling Upgrade (cluster)

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

## Vault Usage

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
