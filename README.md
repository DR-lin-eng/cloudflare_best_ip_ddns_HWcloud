# cloudflare_best_ip_ddns_HWcloud
# 以下readme由ai生成
DDNS Updater Docker 部署指南
项目简介
DDNS Updater 是一个用于动态测试优选cloudflare ip更新的 Python 脚本，支持 IPv4 和 IPv6 地址的自动更新。该脚本使用华为云 DNS 服务，通过 Docker 容器化部署，确保高效、可靠地运行，并且能够轻松管理和监控日志文件。

目录
前提条件
安装和部署步骤
1. 克隆或下载项目
2. 创建 requirements.txt
3. 编写 Dockerfile
4. 创建自定义 Docker 网络
5. 构建 Docker 镜像
6. 创建日志文件
7. 运行 Docker 容器
8. 验证部署
9. 使用 Docker Compose（可选）
查看日志
停止和移除容器
常见问题排查
安全性提示
许可证
前提条件
在开始之前，请确保您的系统满足以下要求：

操作系统：Linux（推荐使用 Ubuntu 或 CentOS）
Docker：已安装并运行
安装指南：Docker 官方文档
Docker Compose（可选）：用于简化多容器管理
安装指南：Docker Compose 官方文档
华为云账号：拥有 DNS 服务的访问密钥（ACCESS_KEY 和 SECRET_KEY）
安装和部署步骤
1. 克隆或下载项目
首先，克隆本项目的仓库到您的本地机器：

bash
复制代码
git clone https://github.com/your-repo/ddns_updater.git
cd ddns_updater
如果您没有使用 Git，可以直接下载项目压缩包并解压到目标目录。

2. 创建 requirements.txt
确保项目目录中有一个 requirements.txt 文件，列出所有 Python 依赖项。内容如下：

plaintext
复制代码
aiohttp
requests
huaweicloudsdkcore
huaweicloudsdkdns
如果您已经有 requirements.txt 文件，可以跳过此步骤。

3. 编写 Dockerfile
在项目根目录中创建一个名为 Dockerfile 的文件，并添加以下内容：

dockerfile
复制代码
# 使用官方轻量级 Python 基础镜像
FROM python:3.12-slim

# 设置工作目录
WORKDIR /app

# 安装必要的网络工具和依赖项
RUN apt-get update && \
    apt-get install -y --no-install-recommends iproute2 iputils-ping curl && \
    rm -rf /var/lib/apt/lists/*

# 将 requirements.txt 复制到容器中
COPY requirements.txt .

# 安装 Python 依赖项
RUN pip install --no-cache-dir -r requirements.txt

# 将当前目录的内容复制到容器中
COPY . .

# 定义环境变量（将在运行容器时传递）
ENV ACCESS_KEY=""
ENV SECRET_KEY=""

# 定义容器启动时运行的命令
CMD ["python", "测活.py"]
说明：

iproute2：提供 ip 命令。
iputils-ping：提供 ping6 命令。
curl：用于网络请求。
4. 创建自定义 Docker 网络
为了确保容器具有独立的 IPv4 和 IPv6 地址，创建一个支持 IPv6 的自定义桥接网络。

注意：在创建网络之前，请确保选择的子网不与现有 Docker 网络重叠。

bash
复制代码
docker network create \
  --driver bridge \
  --ipv6 \
  --subnet 172.30.0.0/16 \
  --subnet 2001:db8:2::/64 \
  custom-bridge-net
常见错误：

子网重叠：如果出现 Pool overlaps with other one on this address space 错误，选择不同的子网范围。例如：

bash
复制代码
docker network create \
  --driver bridge \
  --ipv6 \
  --subnet 172.31.0.0/16 \
  --subnet 2001:db8:3::/64 \
  custom-bridge-net
验证网络创建：

bash
复制代码
docker network inspect custom-bridge-net
应看到类似以下内容：

json
复制代码
[
    {
        "Name": "custom-bridge-net",
        "Id": "a1b2c3d4e5f6...",
        "Created": "2024-04-27T10:05:00.000000000Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": true,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.30.0.0/16",
                    "Gateway": "172.30.0.1"
                },
                {
                    "Subnet": "2001:db8:2::/64",
                    "Gateway": "2001:db8:2::1"
                }
            ]
        },
        ...
    }
]
5. 构建 Docker 镜像
在项目目录中运行以下命令构建 Docker 镜像：

bash
复制代码
docker build -t ddns_updater .
说明：

-t ddns_updater：为镜像命名为 ddns_updater。
.：指定 Dockerfile 位于当前目录。
6. 创建日志文件
确保在主机的当前目录中存在 ddns_update.log 文件，用于存储容器内的日志。

bash
复制代码
touch ddns_update.log
如果您使用 Windows，可以使用以下命令：

powershell
复制代码
New-Item ddns_update.log -ItemType File -Force
7. 运行 Docker 容器
使用自定义桥接网络运行容器，并映射日志文件，同时传递环境变量。

bash
复制代码
docker run -d \
  --name ddns_updater \
  --network custom-bridge-net \
  -e ACCESS_KEY=S4YPA8LYCGG95FEFE6SQ \
  -e SECRET_KEY=vpyvWlKgV2UdKeuf0iIacFevSBZwTTzKiaA0SCjV \
  -v "$(pwd)/ddns_update.log:/app/ddns_update.log" \
  ddns_updater
说明：

-d：以后台模式运行容器。
--name ddns_updater：为容器命名为 ddns_updater。
--network custom-bridge-net：将容器连接到自定义桥接网络。
-e ACCESS_KEY=... 和 -e SECRET_KEY=...：通过环境变量传递华为云密钥。请确保替换为您的实际密钥。
-v "$(pwd)/ddns_update.log:/app/ddns_update.log"：将主机当前目录中的 ddns_update.log 文件映射到容器内的 /app/ddns_update.log。
Windows 用户：

在 PowerShell 中，使用反引号（`）作为换行符：

powershell
复制代码
docker run -d `
  --name ddns_updater `
  --network custom-bridge-net `
  -e ACCESS_KEY=S4YPA8LYCGG95FEFE6SQ `
  -e SECRET_KEY=vpyvWlKgV2UdKeuf0iIacFevSBZwTTzKiaA0SCjV `
  -v "${PWD}\ddns_update.log:/app/ddns_update.log" `
  ddns_updater
8. 查看容器的 IP 地址
使用以下命令查看容器在自定义网络中的 IPv4 和 IPv6 地址：

bash
复制代码
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{.GlobalIPv6Address}}{{end}}' ddns_updater
示例输出：

ruby
复制代码
172.30.0.2 2001:db8:2::2
9. 使用 Docker Compose（可选）
为了简化部署和管理，可以使用 Docker Compose。以下是详细的配置和步骤。

a. 创建 docker-compose.yml
在项目目录中创建一个名为 docker-compose.yml 的文件，并添加以下内容：

yaml
复制代码
version: '3.8'

services:
  ddns_updater:
    image: ddns_updater
    container_name: ddns_updater
    networks:
      custom-bridge-net:
        ipv6_address: 2001:db8:2::10  # 可选，手动指定容器的 IPv6 地址
    environment:
      - ACCESS_KEY=${ACCESS_KEY}
      - SECRET_KEY=${SECRET_KEY}
    volumes:
      - ./ddns_update.log:/app/ddns_update.log
    restart: unless-stopped

networks:
  custom-bridge-net:
    external: true
    name: custom-bridge-net
说明：

network_mode 替换为连接到 custom-bridge-net。
ipv6_address：可选，手动指定容器的 IPv6 地址。
environment：通过环境变量传递 ACCESS_KEY 和 SECRET_KEY。
volumes：映射日志文件。
restart: unless-stopped：确保容器在崩溃后自动重启，除非手动停止。
b. 创建 .env 文件
为了管理环境变量，创建一个 .env 文件并添加以下内容：

dotenv
复制代码
ACCESS_KEY=S4YPA8LYCGG95FEFE6SQ
SECRET_KEY=vpyvWlKgV2UdKeuf0iIacFevSBZwTTzKiaA0SCjV
安全性提示：绝对不要 将 .env 文件提交到版本控制系统（如 Git）。在 .gitignore 文件中添加 .env 以防止意外泄露。

c. 运行 Docker Compose
在项目目录中运行以下命令启动容器：

bash
复制代码
docker-compose up -d
说明：

up：构建并启动容器。
-d：以后台模式运行。
d. 查看容器的 IP 地址
使用以下命令查看容器在自定义网络中的 IPv4 和 IPv6 地址：

bash
复制代码
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{.GlobalIPv6Address}}{{end}}' ddns_updater
示例输出：

ruby
复制代码
172.30.0.2 2001:db8:2::10
e. 查看实时日志
要实时查看容器的日志，可以使用以下命令：

bash
复制代码
docker-compose logs -f
或者使用 Docker CLI：

bash
复制代码
docker logs -f ddns_updater
查看日志
日志文件 ddns_update.log 被映射到主机的当前目录，您可以通过以下方式查看日志：

bash
复制代码
cat ddns_update.log
或者使用 tail 实时查看新增日志：

bash
复制代码
tail -f ddns_update.log
停止和移除容器
使用 Docker CLI
停止容器：

bash
复制代码
docker stop ddns_updater
移除容器：

bash
复制代码
docker rm ddns_updater
使用 Docker Compose
停止并移除容器：

bash
复制代码
docker-compose down
常见问题排查
问题 1：创建网络时子网重叠
错误信息：

csharp
复制代码
Error response from daemon: Pool overlaps with other one on this address space
解决方案：

选择一个不与现有 Docker 网络重叠的子网。例如，将子网更改为 172.31.0.0/16 和 2001:db8:3::/64。
问题 2：容器内无法使用 IPv6
检查步骤：

进入容器：

bash
复制代码
docker exec -it ddns_updater /bin/bash
检查 IPv6 地址：

bash
复制代码
ip -6 addr show
测试 IPv6 连接：

bash
复制代码
ping6 baidu.com
curl -6 http://ipv6.google.com
可能原因及解决方法：

网络配置错误：确保自定义网络正确配置了 IPv6 子网。
防火墙阻挡：检查主机防火墙设置，确保允许 IPv6 流量。
应用程序不支持 IPv6：确保 Python 脚本正确处理 IPv6 地址。
问题 3：容器内缺少命令或工具
解决方案：

确保 Dockerfile 中安装了必要的工具 (iproute2、iputils-ping 和 curl)。

重新构建镜像：

bash
复制代码
docker build -t ddns_updater .
问题 4：环境变量未正确传递
解决方案：

确认 .env 文件位于项目目录中，并且包含正确的 ACCESS_KEY 和 SECRET_KEY。
检查 docker-compose.yml 是否正确引用了环境变量。
问题 5：日志文件未正确映射
解决方案：

确认主机上的 ddns_update.log 文件路径正确，并且具有写权限。

检查挂载选项是否正确：

bash
复制代码
-v "$(pwd)/ddns_update.log:/app/ddns_update.log"
安全性提示
保护敏感信息：

不要 在 Dockerfile 中硬编码 ACCESS_KEY 和 SECRET_KEY。
使用 .env 文件或 Docker Secrets 管理环境变量。
确保 .env 文件不被提交到版本控制系统。
限制容器权限：

使用非 root 用户运行容器（可在 Dockerfile 中设置）。
仅挂载必要的卷，限制对主机文件系统的访问。
定期更新镜像和依赖：

使用最新的基础镜像和依赖库，以修复已知的安全漏洞。
防火墙配置：

确保主机防火墙仅允许必要的流量，尤其是在开放 IPv6 端口时。
许可证
本项目采用 MIT 许可证。

感谢您使用 DDNS Updater！ 如果您有任何问题或建议，请随时联系项目维护者或提交 Issue。
