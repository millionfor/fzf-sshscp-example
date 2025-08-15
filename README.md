## 介绍

基于 fzf 的交互式 SSH/ SCP 小工具：
- `ssh.sh`：模糊搜索服务器并一键连接，支持按 Tab 复制主机名到剪贴板
- `scp.sh`：模糊选择服务器与文件，交互式生成/执行 scp 命令（支持复制命令）

## 依赖

- 必需：
  - `bash`
  - `ssh` / `scp`
  - `fzf`
- 可选：
  - `lemonade`（用于“复制命令到剪贴板”；未安装时复制功能不可用）

在 macOS 可通过 Homebrew 安装：

```bash
brew install fzf
brew install lemonade # 可选
```

## 安装与配置

1) 将仓库中的三个脚本放到 `~/.ssh` 目录（或任意目录）：

```bash
mkdir -p ~/.ssh
cp ssh.sh scp.sh servers.sh config ~/.ssh/
chmod +x ~/.ssh/ssh.sh ~/.ssh/scp.sh ~/.ssh/servers.sh
```

2) 推荐添加别名（在 `~/.zshrc` 或 `~/.bashrc`）：

```bash
alias ssh=~/.ssh/ssh.sh
alias scp=~/.ssh/scp.sh
```

3) 服务器配置文件：同目录下的 `config`

`servers.sh` 会解析与其同目录的 `config` 文件（可通过环境变量 `CONFIG_FILE` 覆盖），字段映射大致等价于 OpenSSH 的配置项：

支持的字段：`Host`、`HostName`、`Port`、`User`、`ServerAliveInterval`、`RequestTTY`、`PreferredAuthentications`、`IdentityFile`。

示例 `config`：

```sshconfig
# 一个最小示例（端口未写时展示为 22）
Host web-1
    HostName 10.0.0.11
    User ubuntu

# 带端口与密钥文件
Host db-1
    HostName 10.0.0.21
    Port 2222
    User admin
    IdentityFile ~/.ssh/id_rsa_db

# 更多可选项
Host bastion
    HostName bastion.company.net
    User ops
    ServerAliveInterval 60
    RequestTTY yes
    PreferredAuthentications publickey
```

解析规则（摘自 `servers.sh`）：
- `HostName` 省略时用 `Host` 作为主机名显示/连接
- `User` 省略时使用当前 `$USER`
- `Port` 展示默认为 22；实际 ssh 命令中仅在为数字时追加 `-p <port>`
- 生成的 ssh 参数会传递给 `scp.sh` 并自动转换：`-p` → `-P`，`-i`/`-o` 原样复用
- 也可通过环境变量覆盖配置路径：`CONFIG_FILE=/path/to/config ~/.ssh/ssh.sh`

## 使用方式

### 1) 交互式 SSH（ssh.sh）

直接执行（或使用上面配置的别名 `ssh`）：

```bash
~/.ssh/ssh.sh
```

交互说明：
- 进入 fzf 列表，显示为：`Host<TAB>Port`
- 预览窗口显示实际将要执行的命令：`ssh [args] user@host`
- 按回车：连接所选服务器
- 按 Tab：复制所选主机名（`HostName` 展开后）到剪贴板，依赖 `lemonade`

兼容原生 ssh：

```bash
# 有任何参数时，原样透传给系统 ssh
~/.ssh/ssh.sh -i ~/.ssh/id_rsa user@1.2.3.4
```

### 2) 交互式 SCP（scp.sh）

直接执行（或使用别名 `scp`）：

```bash
~/.ssh/scp.sh
```

交互流程：
1. 选择服务器（同 `ssh.sh` 列表与预览）
2. 选择方向：
   - “从本地到远程” → 选择本地文件/目录（带预览）
   - “从远程到本地” → 使用远程 `ls` 列表选择（注：经跳板机时可能无法 `ls`）
3. 生成命令并二选一：
   - “复制命令” → 将完整 scp 命令复制到剪贴板（依赖 `lemonade`）
   - “执行命令” → 直接执行生成的 scp 命令

命令格式（示例）：
- 本地 → 远程：`scp -r [映射后的 ssh 参数(含 -P/-i/-o ...)] /path/to/src user@host:~`
- 远程 → 本地：`scp -r [映射后的 ssh 参数] user@host:[REMOTE_PATH] .`

兼容原生 scp：

```bash
# 有任何参数时，原样透传给系统 scp
~/.ssh/scp.sh -i ~/.ssh/id_rsa file user@host:/tmp/
```

## 工作原理（简述）

- `servers.sh` 解析 `config`，构造四个数组：
  - `servers`：用于列表显示（形如 `Host<TAB>Port`）
  - `cmds`：每项对应的 `ssh` 前缀参数（如 `ssh -p 2222 -i xxx -o ...`）
  - `targets`：远程目标（`user@hostname`）
  - `hosts`：仅主机名（用于复制）
- `ssh.sh`/`scp.sh` 通过 `_index` 在数组中定位所选项，并根据 `cmds`/`targets` 拼接命令
- `scp.sh` 会将 `ssh` 参数转换为 `scp` 可接受的：将 `-p` 替换为 `-P`，`-i` 与 `-o` 直接沿用

## 常见问题

- 未安装 `fzf`：请先安装并确保在 `$PATH` 中
- 未安装 `lemonade`：复制相关功能不可用，但不影响连接/传输
- 远程列表为空或无法 `ls`：经跳板机时 `scp.sh` 的远程 `ls` 可能不可用，建议手动输入或选择“复制命令”再自行修改

## 参考/演示

[演示视频:BV1yD4y1474e](https://www.bilibili.com/video/BV1yD4y1474e)

