FROM node:20-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. 替换源以加速下载 (Debian 12 Bookworm 专用路径)
RUN sed -i 's#deb.debian.org#mirrors.aliyun.com#g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's#security.debian.org#mirrors.aliyun.com#g' /etc/apt/sources.list.d/debian.sources

# 2. 安装核心工具及 SSH 服务
RUN apt-get update && apt-get install -y \
    openssh-server \
    rclone \
    vim \
    screen \
    curl \
    wget \
    unzip \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. 配置 SSH (允许 root 登录并设置指定密码)
RUN mkdir /var/run/sshd && \
    echo 'root:1479696753' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

# 4. 安装 Wrangler
RUN npm config set registry https://registry.npmmirror.com && \
    npm install -g wrangler

WORKDIR /app

# 5. 暴露 22 端口
EXPOSE 22

# 6. 启动 SSH 服务
CMD ["/usr/sbin/sshd", "-D"]
