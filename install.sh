#!/bin/bash

set -e

CodePath="./NexusPHP"
DataPath="./data"
LogPath="./log"

# Remove the code directory if it exists
if [ -d "$CodePath" ]; then
    rm -rf "$CodePath"
fi

# Remove the data directory if it exists
if [ -d "$DataPath" ]; then
    rm -rf "$DataPath"
fi

# Remove the log directory if it exists
if [ -d "$LogPath" ]; then
    rm -rf "$LogPath"
fi

# 克隆子模块
git submodule sync
git submodule update --init --recursive

# 进入子模块目录（假设子模块在 NexusPHP 中）
cd NexusPHP

# 拉取标签并切换到 v1.7.38
git fetch --tags
git checkout tags/v1.7.38

# 返回原目录
cd ..

# Wait for 5 seconds to finish cloning
sleep 5

# Copy the install files to the public directory
sourceDir="./NexusPHP/nexus/Install/install"
targetDir="./NexusPHP/public/install"

# Retry copying files if sourceDir exists
while [ ! -d "$sourceDir" ]; do
    sleep 5
done

mkdir -p "$targetDir"
cp -r "$sourceDir/"* "$targetDir/"

# 示例：仅开放上传、缓存等目录
chmod -R 755 ./NexusPHP
chmod -R 777 ./NexusPHP/public \
              ./NexusPHP/storage \
              ./NexusPHP/bootstrap




# Function to generate a random password
generate_password() {
    local length=$1
    local charset=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
    local password=""
    
    for ((i=0; i<length; i++)); do
        local index=$((RANDOM % ${#charset}))
        password+="${charset:$index:1}"
    done
    
    echo "$password"
}

# Generate MySQL and Redis passwords
mysqlpassword=$(generate_password 16)
redispassword=$(generate_password 16)

# Save passwords to a .env file for Docker Compose
{
    echo "MYSQL_ROOT_PASSWORD=$mysqlpassword"
    echo "REDIS_PASSWORD=$redispassword"
} > docker-compose/.env

# Start the application
./start.sh

# Set the SQL script path
CONTAINER_NAME="pt-mysql"
SQL_SCRIPT_PATH="./docker-compose/sql/install.sql"
CONTAINER_SQL_SCRIPT_PATH="/opt/install.sql"


# 1. 验证 SQL 文件存在
if [ ! -f "$SQL_SCRIPT_PATH" ]; then
  echo "错误：找不到 SQL 文件 $SQL_SCRIPT_PATH"
  exit 1
fi

# 2. 等待 MySQL 启动（带超时）
MAX_RETRIES=10
RETRY_COUNT=0
echo "等待 MySQL 启动（最多尝试 $MAX_RETRIES 次）..."
until docker exec $CONTAINER_NAME mysqladmin ping -uroot --password="$mysqlpassword" --silent || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
  sleep 3
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "错误：MySQL 启动超时！"
  exit 1
fi

# 3. Copy the SQL script to the container
docker cp "$SQL_SCRIPT_PATH" "$CONTAINER_NAME":"$CONTAINER_SQL_SCRIPT_PATH"

#  4. Execute the SQL script
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p"$mysqlpassword" < "$CONTAINER_SQL_SCRIPT_PATH"; then
    echo "SQL script execution failed!"
    echo "Please create the database 'nexusphp' using the following command:"
    echo "create database nexusphp default charset=utf8mb4 collate utf8mb4_general_ci;"
else
    echo "SQL script executed successfully!"
fi

echo "Installation completed"