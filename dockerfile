FROM node:20-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's#deb.debian.org#mirrors.aliyun.com#g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's#security.debian.org#mirrors.aliyun.com#g' /etc/apt/sources.list.d/debian.sources

# 安装核心工具 (替换源后速度会大幅提升)
RUN apt-get update && apt-get install -y \
    rclone \
    vim \
    screen \
    curl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 Wrangler
RUN npm config set registry https://registry.npmmirror.com && \
    npm install -g wrangler

WORKDIR /app
CMD ["bash"]
