FROM node:24-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 1. 替换源以加速下载 (Debian 12 Bookworm 专用路径)
RUN sed -i 's#deb.debian.org#mirrors.aliyun.com#g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's#security.debian.org#mirrors.aliyun.com#g' /etc/apt/sources.list.d/debian.sources

# 2. 安装核心工具 (包含 cron, sudo 等)
RUN apt-get update && apt-get install -y \
    openssh-server \
    rclone \
    vim \
    screen \
    curl \
    wget \
    unzip \
    zip \
    ca-certificates \
    cron \
    locales \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. 设置系统时区并解决 perl 警告
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# 4. 【新增】添加用户 hechuan
# 创建用户，指定密码 (这里设为和 root 一样，你可以自行修改)，并加入 sudo 组
RUN useradd -m -s /bin/bash hechuan && \
    echo 'hechuan:1479696753' | chpasswd && \
    adduser hechuan sudo

# 5. 配置 SSH
RUN mkdir /var/run/sshd && \
    echo 'root:1479696753' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

# 4. 安装 Wrangler
RUN npm config set registry https://registry.npmmirror.com && \
    npm install -g wrangler

WORKDIR /home/hechuan

# 7. 暴露端口
EXPOSE 22

# 8. 同时启动 cron 和 sshd
# 确保 cron 启动，sshd 保持前台运行
CMD ["sh", "-c", "service cron start && /usr/sbin/sshd -D"]
