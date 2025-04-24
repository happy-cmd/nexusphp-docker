#!/bin/sh

# 定义环境变量
CRONTAB_DIR="/etc/crontabs"       # Alpine 专用 cron 任务目录
PHP_USER="www-data"               # 确保该用户已存在（需在 Dockerfile 中创建）
ROOT_PATH="/var/www/NexusPHP"
CRON_LOG_DIR="/var/log/cron"      # 推荐统一日志目录

# 创建日志目录并设置权限
mkdir -p "$CRON_LOG_DIR"
chown -R $PHP_USER:$PHP_USER "$CRON_LOG_DIR"
chmod 766 "$CRON_LOG_DIR"

# 定义 cron 任务（日志重定向到统一目录）
CRON_JOB_1="* * * * * cd $ROOT_PATH && php artisan schedule:run >> $CRON_LOG_DIR/schedule.log 2>&1"
CRON_JOB_2="* * * * * cd $ROOT_PATH && php include/cleanup_cli.php >> $CRON_LOG_DIR/cleanup_cli.log 2>&1"

# 写入用户级 cron 任务文件
echo "$CRON_JOB_1" > "$CRONTAB_DIR/$PHP_USER"
echo "$CRON_JOB_2" >> "$CRONTAB_DIR/$PHP_USER"

# 设置权限（必须 600，否则 crond 会忽略）
chmod 600 "$CRONTAB_DIR/$PHP_USER"
chown $PHP_USER "$CRONTAB_DIR/$PHP_USER"

# 加载所有任务（可选）
crond -l 8 -L /dev/stdout &

echo "Crontab entries added successfully for user $PHP_USER."