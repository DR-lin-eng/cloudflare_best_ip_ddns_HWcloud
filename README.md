# cloudflare_best_ip_ddns_HWcloud
# 以下readme由ai生成
# DDNS Updater

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python Version](https://img.shields.io/badge/python-3.12-blue.svg)
![Docker](https://img.shields.io/badge/docker-19.03%2B-blue.svg)

## 简介

**DDNS Updater** 是一个用于动态测试优选 [Cloudflare IP](https://www.cloudflare.com/) 更新的 Python 脚本，支持 IPv4 和 IPv6 地址的自动更新。该脚本使用华为云 DNS 服务，确保您的域名始终指向最佳的 Cloudflare IP 地址，提升访问速度和稳定性。
### 注意：使用前需要修改脚本内的主域名和子域名等信息再使用，建议直接部署，docker部署可能会遇到ipv6的问题请注意

## 目录

- [特点](#特点)
- [前提条件](#前提条件)
- [安装和部署](#安装和部署)
  - [1. 克隆仓库](#1-克隆仓库)
  - [2. 创建自定义 Docker 网络](#2-创建自定义-docker-网络)
  - [3. 构建 Docker 镜像](#3-构建-docker-镜像)
  - [4. 创建日志文件](#4-创建日志文件)
  - [5. 运行 Docker 容器](#5-运行-docker-容器)
  - [6. 验证部署](#6-验证部署)
- [使用 Docker Compose](#使用-docker-compose)
- [查看日志](#查看日志)
- [停止和移除容器](#停止和移除容器)
- [常见问题排查](#常见问题排查)
- [安全性提示](#安全性提示)
- [许可证](#许可证)

## 特点

- **动态测试**：定期测试并优选 Cloudflare 的最佳 IP 地址。
- **IPv4 和 IPv6 支持**：同时支持 IPv4 和 IPv6 地址的自动更新。
- **华为云 DNS 集成**：使用华为云 DNS 服务进行域名解析更新。
- **Docker 容器化**：通过 Docker 容器化部署，简化安装和管理。
- **日志管理**：日志文件自动映射到主机，便于监控和调试。

## 前提条件

在开始之前，请确保您的系统满足以下要求：

1. **操作系统**：Linux（推荐使用 Ubuntu 或 CentOS）
2. **Docker**：已安装并运行
   - 安装指南：[Docker 官方文档](https://docs.docker.com/get-docker/)
3. **Docker Compose**（可选）：用于简化多容器管理
   - 安装指南：[Docker Compose 官方文档](https://docs.docker.com/compose/install/)
4. **华为云账号**：拥有 DNS 服务的访问密钥（`ACCESS_KEY` 和 `SECRET_KEY`）

## 安装和部署

### 1. 克隆仓库

首先，克隆本项目的仓库到您的本地机器：

```bash
git clone https://github.com/DR-lin-eng/cloudflare_best_ip_ddns_HWcloud.git
cd cloudflare_best_ip_ddns_HWcloud
```

*如果您没有使用 Git，可以直接下载项目压缩包并解压到目标目录。*

### 2. 创建自定义 Docker 网络

为了确保容器具有独立的 IPv4 和 IPv6 地址，创建一个支持 IPv6 的自定义桥接网络。

**注意**：在创建网络之前，请确保选择的子网不与现有 Docker 网络重叠。

```bash
docker network create \
  --driver bridge \
  --ipv6 \
  --subnet 172.30.0.0/16 \
  --subnet 2001:db8:2::/64 \
  custom-bridge-net
```

**常见错误**：

- **子网重叠**：如果出现 `Pool overlaps with other one on this address space` 错误，选择不同的子网范围。例如：

  ```bash
  docker network create \
    --driver bridge \
    --ipv6 \
    --subnet 172.31.0.0/16 \
    --subnet 2001:db8:3::/64 \
    custom-bridge-net
  ```

**验证网络创建**：

```bash
docker network inspect custom-bridge-net
```

### 3. 构建 Docker 镜像

确保您的 `Dockerfile` 已正确配置并安装了必要的网络工具。

#### 示例 `Dockerfile`

```dockerfile
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
```

#### 构建镜像

在项目目录中运行以下命令构建 Docker 镜像：

```bash
docker build -t ddns_updater .
```

### 4. 创建日志文件

确保在主机的当前目录中存在 `ddns_update.log` 文件，用于存储容器内的日志。

```bash
touch ddns_update.log
```

### 5. 运行 Docker 容器

使用自定义桥接网络运行容器，并映射日志文件，同时传递环境变量。

```bash
docker run -d \
  --name ddns_updater \
  --network custom-bridge-net \
  -e ACCESS_KEY=你的_ACCESS_KEY_ \
  -e SECRET_KEY=你的_SECRET_KEY_ \
  -v "$(pwd)/ddns_update.log:/app/ddns_update.log" \
  ddns_updater
```

**说明**：

- 请替换 `你的_ACCESS_KEY_` 和 `你的_SECRET_KEY_` 为您的华为云密钥。

### 6. 验证部署

#### 查看容器是否正在运行

```bash
docker ps
```

应看到类似以下内容：

```
CONTAINER ID   IMAGE           COMMAND                  CREATED          STATUS          PORTS     NAMES
abcdef123456   ddns_updater    "python 测活.py"        10 seconds ago   Up 8 seconds              ddns_updater
```

#### 查看容器的 IP 地址

使用以下命令查看容器在自定义网络中的 IPv4 和 IPv6 地址：

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{.GlobalIPv6Address}}{{end}}' ddns_updater
```

**示例输出**：

```
172.30.0.2 2001:db8:2::2
```

## 使用 Docker Compose

为了简化部署和管理，您可以使用 Docker Compose。以下是详细的步骤和配置文件。

### 1. 创建 `docker-compose.yml`

在项目目录中创建一个名为 `docker-compose.yml` 的文件，并添加以下内容：

```yaml
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
```

### 2. 创建 `.env` 文件

为了管理环境变量，创建一个 `.env` 文件并添加以下内容：

```dotenv
ACCESS_KEY=你的_ACCESS_KEY_
SECRET_KEY=你的_SECRET_KEY_
```

**安全性提示**：**绝对不要** 将 `.env` 文件提交到版本控制系统（如 Git）。在 `.gitignore` 文件中添加 `.env` 以防止意外泄露。

### 3. 运行 Docker Compose

在项目目录中运行以下命令启动容器：

```bash
docker-compose up -d
```

### 4. 查看实时日志

要实时查看容器的日志，可以使用以下命令：

```bash
docker-compose logs -f
```

## 查看日志

日志文件 `ddns_update.log` 被映射到主机的当前目录，您可以通过以下方式查看日志：

```bash
cat ddns_update.log
```

或使用 `tail` 实时查看新增日志：

```bash
tail -f ddns_update.log
```

## 停止和移除容器

### 使用 Docker CLI

1. **停止容器**：

   ```bash
   docker stop ddns_updater
   ```

2. **移除容器**：

   ```bash
   docker rm ddns_updater
   ```

### 使用 Docker Compose

1. **停止并移除容器**：

   ```bash
   docker-compose down
   ```

## 安全性提示

1. **保护敏感信息**：
   - **不要** 在 `Dockerfile` 中硬编码 `ACCESS_KEY` 和 `SECRET_KEY`。
   - 使用 `.env` 文件或 Docker Secrets 管理环境变量。
   - 确保 `.env` 文件不被提交到版本控制系统。

2. **限制容器权限**：
   - 使用非 root 用户运行容器（可在 `Dockerfile` 中设置）。
   - 仅挂载必要的卷，限制对主机文件系统的访问。

3. **定期更新镜像和依赖**：
   - 使用最新的基础镜像和依赖库，以修复已知的安全漏洞。

4. **防火墙配置**：
   - 确保主机防火墙仅允许必要的流量，尤其是在开放 IPv6 端口时。

## 许可证

本项目采用 [MIT 许可证](LICENSE)。

---

**感谢您使用 DDNS Updater！** 如果您有任何问题或建议，请随时联系项目维护者或提交 [Issue](https://github.com/DR-lin-eng/cloudflare_best_ip_ddns_HWcloud/issues)。

