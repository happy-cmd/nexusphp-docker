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

# # Copy the install files to the public directory
# sourceDir="./NexusPHP/nexus/Install/install"
# targetDir="./NexusPHP/public/install"

# # Retry copying files if sourceDir exists
# while [ ! -d "$sourceDir" ]; do
#     sleep 5
# done

# mkdir -p "$targetDir"
# cp -r "$sourceDir/"* "$targetDir/"

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


# 3.等待 MySQL 启动（无警告）
echo "等待 MySQL 启动..."
until docker exec $CONTAINER_NAME sh -c "MYSQL_PWD=${mysqlpassword} mysqladmin ping -uroot --silent"; do
  sleep 3
done

# 4.执行初始化脚本
echo "执行数据库初始化脚本..."
if ! docker exec -i "$CONTAINER_NAME" sh -c "export MYSQL_PWD='${mysqlpassword}'; mysql -u root -h 127.0.0.1" < "$SQL_SCRIPT_PATH"; then
    echo "SQL 脚本执行失败！"
    echo "请手动执行以下命令修复："
    echo "docker exec -it pt-mysql mysql -u root -p'${mysqlpassword}' -e \"CREATE DATABASE nexusphp DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;\""
    exit 1
else
    echo "SQL 脚本执行成功！"
fi

echo "Installation completed"