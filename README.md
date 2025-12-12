# Vnet 隧道一键安装脚本

本脚本用于快速安装与管理 Vnet 隧道的控制端与服务端，现已在 CentOS/RHEL 与 Debian 12 上适配运行，并提供 systemd 管理、NAT 转发、防火墙持久化、端口可配置等增强功能。

## 支持环境
- CentOS 7+/RHEL 系列（使用 `yum` 与 `iptables-services`）
- Debian 12（使用 `apt-get` 与 `iptables-persistent`）
- 需以 `root` 权限执行

## 快速开始
- 以 `root` 运行脚本：`bash /root/vnet.sh` 或使用别名 `vnet`
- 按菜单选择所需操作：
  - 1 安装控制端(普通机器)
  - 2 安装控制端(NAT机器)
  - 3 安装服务端
  - 4 重启控制端
  - 5 重启服务端
  - 6 启用/停用 web 管理(防火墙)
  - 7 卸载控制端
  - 8 卸载服务端
  - 9 查看状态
  - 10 设置端口

## 功能说明
- 安装控制端/服务端
  - 自动下载并解压 `tunnel.zip`，放置二进制 `client` 与 `server` 及静态网页
  - 优先使用 systemd 创建并启用服务：`vnet-client.service`、`vnet-server.service`
  - 不支持 systemd 时回退为 `nohup` 前台安装
- NAT 控制端
  - 在当前服务器上做端口转发：将外部端口转发到控制端 web 端口
  - 避免重复添加规则，并对防火墙规则进行持久化保存
- 防火墙开关
  - 针对 web 管理端口开放或关闭访问，支持当前配置端口
  - 在 Debian 使用 `netfilter-persistent save`，在 CentOS 使用 `service iptables save`，否则兜底写入 `/etc/iptables/rules.v4`
- 端口可配置与持久化
  - 客户端与服务端端口可通过菜单 10 设置
  - 端口配置存储于 ` /root/.vnet.conf`，重启脚本自动加载
- 状态查看
  - 展示 IPv4、客户端/服务端运行状态
  - 链接展示采用“按状态显示”的策略：
    - 客户端仅在 `active` 时展示管理链接
    - 服务端在 `active` 或 `activating` 时展示管理链接
- 卸载
  - 删除对应 systemd 单元并禁用
  - 清理 `client` 或 `server` 二进制

## 管理地址
- 控制端：`http://<服务器IPv4>:<客户端端口>/resources/add_client.html`
- 服务端：`http://<服务器IPv4>:<服务端端口>/resources/add_server.html`
- 默认端口：客户端 `8080`，服务端 `8081`（可在菜单 10 中修改）

## 常用命令
- 查看服务状态：
  - `systemctl status vnet-client.service`
  - `systemctl status vnet-server.service`
- 查看日志：
  - `journalctl -u vnet-client.service -n 100 --no-pager`
  - `journalctl -u vnet-server.service -n 100 --no-pager`
- 启动/停止/重启：
  - `systemctl start|stop|restart vnet-client.service`
  - `systemctl start|stop|restart vnet-server.service`

## 常见问题
- 客户端/服务端为 `inactive`
  - 未安装或安装失败：重新执行安装菜单项
  - systemd 未启用：`systemctl enable --now vnet-*.service`
  - 二进制缺失：检查 `/root/client`、`/root/server` 是否存在与可执行
- 无法访问管理页面
  - 确认防火墙已开放当前端口（菜单 6）
  - 在 NAT 模式下，确认外部端口映射正确且已持久化保存
- IPv4 显示为空或错误
  - 机器优先返回 IPv6 时，通过脚本会强制 `curl -4` 获取公网 IPv4 并在失败时回退到 `hostname -I`

## 安全提示
- Web 管理端口应按需开放，建议仅在配置阶段临时开启，完成后关闭
- 请妥善保管服务器访问权限，避免管理页面被未授权访问

## 变更概览
- Debian 12 适配：安装依赖、持久化防火墙、kill 命令降级
- systemd 管理：服务自启与异常重启
- 端口配置与持久化：` /root/.vnet.conf`
- NAT 转发规则优化：重复检查与持久化保存
- 链接展示优化：按运行状态选择性显示

