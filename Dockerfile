FROM php:8.1-fpm-alpine

# 替换镜像源加速国内构建
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装系统依赖（新增 bash 用于调试）
RUN apk add --no-cache \
    bash \
    libpng-dev \
    libjpeg-turbo-dev \
    zlib-dev \
    hiredis-dev \
    gmp-dev \
    git \
    dcron  # Alpine 的 cron 实现

# 配置 PHP 生产环境
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# 设置工作目录
WORKDIR /var/www/NexusPHP

# 安装 PHP 扩展（使用国内镜像加速）
ENV PHP_EXTENSIONS_MIRROR=https://mirrors.aliyun.com/pecl/
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
    bcmath \
    ctype \
    curl \
    fileinfo \
    json \
    mbstring \
    openssl \
    pdo_mysql \
    tokenizer \
    xml \
    mysqli \
    gd \
    redis \
    pcntl \
    sockets \
    posix \
    gmp \
    opcache \
    ftp

# 创建必要目录并设置权限
RUN mkdir -p /tmp /var/log/cron /etc/cron.d \
    && chmod 1777 /tmp \
    && touch /var/log/cron/cron.log \
    && chmod 666 /var/log/cron/cron.log

# 安装 Composer
ENV COMPOSER_PROCESS_TIMEOUT=1200
RUN install-php-extensions @composer

# 复制应用代码
COPY NexusPHP/. ./

EXPOSE 9000