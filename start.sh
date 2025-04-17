#!/bin/bash

set -e

# Function to get user input
ask_mysql() {
    read -p "Do you want to start MySQL service? [Y/n] " mysql_input
    mysql_choice=${mysql_input:-y}
}

ask_redis() {
    read -p "Do you want to start Redis service? [Y/n] " redis_input
    redis_choice=${redis_input:-y}
}

ask_mysql
ask_redis

# Initialize the passwords
mysqlpassword=""
redispassword=""

# Get the passwords from the .env file
while IFS='=' read -r key value; do
    case "$key" in
        MYSQL_ROOT_PASSWORD) mysqlpassword="$value" ;;
        REDIS_PASSWORD) redispassword="$value" ;;
    esac
done < <(grep -E 'MYSQL_ROOT_PASSWORD|REDIS_PASSWORD' docker-compose/.env)

# Determine which docker-compose file to use
if [[ "$mysql_choice$redis_choice" == "nn" ]]; then
    echo "Starting services with docker-compose.yml..."
    docker-compose up -d
elif [[ "$mysql_choice$redis_choice" == "yn" ]]; then
    echo "Root MySQL password: $mysqlpassword"
    docker-compose -f docker-compose/docker-compose10.yml up -d
elif [[ "$mysql_choice$redis_choice" == "ny" ]]; then
    echo "Redis password: $redispassword"
    docker-compose -f docker-compose/docker-compose01.yml up -d
elif [[ "$mysql_choice$redis_choice" == "yy" ]]; then
    echo "Root MySQL password: $mysqlpassword"
    echo "Redis password: $redispassword"
    docker-compose -f docker-compose/docker-compose11.yml up -d
else
    echo "Unexpected case. Please check your input."
    exit 1
fi

# Set the container name and bash script path
CONTAINER_NAME="pt-php"
BASH_SCRIPT_PATH="./docker-compose/sh/timetask.sh"
CONTAINER_BASH_SCRIPT_PATH="/opt/timetask.sh"

# 1. 确保目标目录存在
docker exec $CONTAINER_NAME mkdir -p /opt

# 2. 复制定时任务脚本
echo "复制定时任务脚本到容器..."
docker cp "$BASH_SCRIPT_PATH" "$CONTAINER_NAME":"$CONTAINER_BASH_SCRIPT_PATH"

# 3. 设置用户和权限
docker exec $CONTAINER_NAME sh -c "\
  if ! id www-data >/dev/null 2>&1; then \
    adduser -D -s /bin/sh -u 1000 www-data; \
  fi && \
  chown www-data:www-data $CONTAINER_BASH_SCRIPT_PATH && \
  chmod +x $CONTAINER_BASH_SCRIPT_PATH"



# 4. 执行定时任务设定
echo "设置定期任务..."
docker exec $CONTAINER_NAME sh -c "\
  # 确保 /tmp 目录权限正确（防止运行时被修改）
  chmod 1777 /tmp && \
  # 创建用户（若不存在）
  if ! id www-data >/dev/null 2>&1; then \
    adduser -D -s /bin/sh -u 1000 www-data; \
  fi && \
  # 写入定时任务
  echo '*/5 * * * * www-data php /var/www/NexusPHP/artisan schedule:run' > /etc/cron.d/nexusphp && \
  # 设置权限
  chown root:root /etc/cron.d/nexusphp && \
  chmod 0644 /etc/cron.d/nexusphp && \
  # 启动 cron 服务（dcron 使用 crond 命令）
  crond -b"

# Execute the bash script in the container
if ! docker exec -it "$CONTAINER_NAME" sh -c "sh $CONTAINER_BASH_SCRIPT_PATH"; then
    echo "Timed task script execution failed!"
    echo "Please enter the container and execute related commands manually."
else
    echo "Timed task script executed successfully!"
fi