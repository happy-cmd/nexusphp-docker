FROM php:8.1-fpm-alpine

# 替换 Alpine 源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装系统依赖包（提前安装加速后续扩展编译）
RUN apk add --no-cache \
    libpng-dev \
    libjpeg-turbo-dev \
    zlib-dev \
    hiredis-dev \
    gmp-dev

# 使用默认生产环境 PHP 配置
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# 设置工作目录
WORKDIR /var/www/NexusPHP

# 创建 /tmp 目录并设置权限
RUN mkdir -p /tmp && chmod 1777 /tmp


# 复制文件到容器中
COPY NexusPHP/. .

# 将目录所有权赋予 www-data 用户/组（Alpine 中默认的 PHP-FPM 用户）
RUN chown -R www-data:www-data /var/www/NexusPHP

# 安装依赖包和 PHP 扩展
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

# 安装 Composer
ENV COMPOSER_PROCESS_TIMEOUT=1200
RUN install-php-extensions @composer


EXPOSE 9000