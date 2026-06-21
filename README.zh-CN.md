# ansible-role-garage（中文）

在 Linux 上以 systemd 服务的形式安装、配置并升级 [Garage](https://garagehq.deuxfleurs.fr/) 对象存储的 Ansible role。

> 本文以**基本配置示例**为主。完整变量参考、全部说明与进阶示例请见英文文档：[README.md](README.md) 与 [EXAMPLES.md](EXAMPLES.md)。

## 功能简介

- 创建用户与用户组
- 下载并安装二进制（仅在缺失时安装；仅在开启升级且目标版本更高时升级）
- SHA256 校验（支持自定义校验值）
- 渲染 TOML 配置与环境变量文件
- 配置并管理 systemd 服务
- 服务启动后校验端口监听，可选 admin API 健康检查
- 升级流程：备份旧二进制、重启服务、自动比对版本以避免不必要的升级与降级
- 集群引导：通过 `garage node connect` 组网（`garage_cluster_connect`）+ 首次布局初始化（`garage_layout_init`），均为可选

## 环境要求

- Ansible >= 2.18
- 目标主机支持 systemd
- 可访问网络以下载 Garage 二进制（目标主机；或使用 `garage_download_local` 时为控制端）

支持架构：x86_64、ARM64 (aarch64)、ARMv7l、i386。已在 Debian 12 上测试。

## 快速开始

最小化全新安装。`garage_rpc_secret` 为**必填**项，建议用 `openssl rand -hex 32` 生成并存入 ansible-vault：

```yaml
- name: Install Garage
  hosts: storage
  become: true
  vars:
    garage_rpc_secret: "{{ vault_garage_rpc_secret }}"
  roles:
    - eyebrowkang.garage
```

## 常用变量

仅列最常用项；完整变量表见 [README.md](README.md#role-variables)。

| 变量                        | 默认值                | 说明                                              |
| --------------------------- | --------------------- | ------------------------------------------------- |
| `garage_rpc_secret`         | （必填）              | 节点间 RPC 通信密钥，`openssl rand -hex 32` 生成  |
| `garage_version`            | `"v2.3.0"`            | 安装/升级的目标版本（必须以 `v` 开头）            |
| `garage_replication_factor` | `1`                   | 副本数（单机 1；生产建议 3）                       |
| `garage_data_dir`           | `"/var/lib/garage/data"` | 单数据盘路径                                   |
| `garage_data_dirs`          | `[]`                  | 多数据盘（路径列表，或 `{path, capacity?, read_only?}`）|
| `garage_db_engine`          | `"lmdb"`              | 数据库引擎（`lmdb` 或 `sqlite`）                  |
| `garage_cluster_connect`    | `false`              | 服务启动后将 play 内主机互相 `garage node connect` |
| `garage_layout_init`        | `false`              | 初始化首个集群布局（仅 0 → 1，不改动已有布局）    |
| `garage_upgrade`            | `false`              | 开启升级模式（仅目标版本更高时升级，禁止降级）    |

## 基本配置示例

### 集群部署

`garage_cluster_connect` 将 play 内各主机组网，`garage_layout_init` 应用**首个**布局。两者默认关闭，顺序为先组网再布局（`garage layout assign` 只接受集群已知的节点 ID）。

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

> zone、capacity、gateway、tags 是**每节点**取值，异构集群请在 `host_vars` 中分别设置。`garage_layout_init` 仅在不存在布局时生效；之后的扩缩容、再平衡均为运维操作，role 不会改动既有布局。

### 多数据盘

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

### 升级

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

> 仅支持同主版本的小版本升级；跨主版本请参考 Garage 官方升级指南手动处理。集群滚动升级（`serial: 1`）示例见 [EXAMPLES.md](EXAMPLES.md#rolling-upgrade-cluster)。

## 自定义配置模板

自带模板覆盖常见场景。如需更细的配置（发现后端、性能调优、额外 API 等），可用 `garage_config_template` 整体替换为你自己的模板。

一旦覆盖，role 会**跳过模板专属校验**（`replication_factor`、`rpc_secret`、`s3_web` 配对、`bootstrap_peers`）——这些变量只服务于自带模板，你需自行校验模板用到的变量。内禀校验（`garage_version`、数据目录、`admin_api_bind_addr` 端口、`garage_upgrade`）仍会执行，用户、目录、环境变量文件与 systemd 服务也照常由 role 管理。

## 密钥管理（ansible-vault）

```bash
ansible-vault create group_vars/storage/vault.yml
```

```yaml
# group_vars/storage/vault.yml
vault_garage_rpc_secret: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
```

## 更多

- 完整变量参考与说明：[README.md](README.md)
- 全部示例（额外选项、滚动升级、vault 等）：[EXAMPLES.md](EXAMPLES.md)
- 开发与测试：[CONTRIBUTING.md](CONTRIBUTING.md)

## 许可证

MIT
