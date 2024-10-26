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
