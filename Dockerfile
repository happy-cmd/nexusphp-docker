FROM php:8.1-fpm-alpine

LABEL maintainer="shenghongzha@gmail.com"

# 替换 Alpine 镜像源为阿里云镜像
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装系统依赖包（提前安装加速后续扩展编译）
RUN apk add --no-cache \
    libpng-dev \
    libjpeg-turbo-dev \
    zlib-dev \
    hiredis-dev \
    gmp-dev \
    git

# 使用默认生产环境 PHP 配置
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# 设置工作目录
WORKDIR /var/www/NexusPHP

# 安装 PHP 扩展（使用国内 PECL 镜像）
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

# 复制应用代码
COPY NexusPHP/. ./

# 创建 /tmp 目录并设置权限（必须先于 dcron 安装）
RUN mkdir -p /tmp && chmod 1777 /tmp

# 安装 cron 并创建目录
RUN apk add --no-cache dcron && \
    mkdir -p /etc/cron.d 

ENV COMPOSER_PROCESS_TIMEOUT=1200
# # 安装 Composer
RUN install-php-extensions @composer


EXPOSE 9000
CMD ["php-fpm"]