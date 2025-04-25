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

# 仅设置 ./log/php 的权限  保证/tmp 可读
chown -R 82:82 "$LogPath/php"
chmod 755 "$LogPath/php"  # 按需调整权限

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


# 仅开放上传、缓存等目录

chmod -R 755 ./NexusPHP
chmod -R 777 ./NexusPHP/public \
              ./NexusPHP/storage \
              ./NexusPHP/bootstrap \
              ./NexusPHP/attachments \
              ./NexusPHP/bitbucket




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
# MySQL 官方镜像支持将 SQL 文件放入 /docker-entrypoint-initdb.d/ 目录，容器首次启动时会自动执行这些 SQL 文件。
CONTAINER_SQL_SCRIPT_PATH="/docker-entrypoint-initdb.d/install.sql"


# 1. 验证 SQL 文件存在
if [ ! -f "$SQL_SCRIPT_PATH" ]; then
  echo "❌ 错误：找不到 SQL 文件 $SQL_SCRIPT_PATH"
  exit 1
fi

# 2. 等待 MySQL 启动（带超时）
MAX_RETRIES=10
RETRY_COUNT=0
echo "⏳ 等待 MySQL 启动（最多尝试 $MAX_RETRIES 次）..."
until docker exec $CONTAINER_NAME mysqladmin ping -uroot --password="$mysqlpassword" --silent || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
  sleep 3
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ 错误：MySQL 启动超时！"
  exit 1
else
  echo "✅ MySQL 已启动"
fi

# 3. 复制 SQL 文件到容器初始化目录
echo "📦 复制 SQL 文件到容器..."
if docker cp "$SQL_SCRIPT_PATH" "$CONTAINER_NAME":"$CONTAINER_SQL_SCRIPT_PATH"; then
  echo "✅ SQL 文件已复制到容器路径: $CONTAINER_SQL_SCRIPT_PATH"
else
  echo "❌ 错误：复制 SQL 文件失败！"
  exit 1
fi

# 4. 重启容器以触发初始化（仅在首次启动时需要）
echo "🔄 重启 MySQL 容器以触发初始化..."
docker restart $CONTAINER_NAME

# 5. 监控初始化日志（带超时）
echo "🔍 检查初始化日志..."
LOG_TIMEOUT=30
LOG_FLAG="executing /docker-entrypoint-initdb.d/install.sql"
if timeout $LOG_TIMEOUT sh -c "while ! docker logs $CONTAINER_NAME 2>&1 | grep -q '$LOG_FLAG'; do sleep 1; done"; then
  echo "✅ SQL 文件已触发执行"
else
  echo "⚠️ 警告：未检测到 SQL 初始化日志（可能已初始化过）"
fi

# 6. 验证数据库是否创建成功
echo "🔎 验证数据库状态..."
DB_EXISTS=$(docker exec $CONTAINER_NAME mysql -u root -p"$mysqlpassword" -sN -e "SHOW DATABASES LIKE 'nexusphp';" 2>/dev/null)
if [ "$DB_EXISTS" = "nexusphp" ]; then
  echo "✅ 数据库 'nexusphp' 创建成功"
else
  echo "❌ 错误：数据库 'nexusphp' 未创建！"
  exit 1
fi

echo "🎉 安装完成"

