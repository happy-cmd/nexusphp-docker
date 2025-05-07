# docker一键快速部署NexusPHP（改）

## 说明

在[docker一键快速部署NexusPHP](https://github.com/shenghongzha/nexusphp-docker) 

> 这是一个docker快速部署nexusphp的脚本项目，包含Dockerfile创建docker镜像，docker-compose启动镜像，便于让nexusphp快速落地。

的基础上，添加一定的改动，补充说明了如何在VMware虚拟机安装ubuntu镜像，配置docker，到最终安装完毕的说明，算是一个更加便于理解的版本。

**注：仅针对原项目在linux下的安装进行了分析说明，对于windows平台下的安装舍弃了，同时指定安装了v1.7.38版本（具体可修改 install.sh 文件）**

## 流程

### 01.虚拟机与docker环境

- [基于VMware虚拟机的Ubuntu22.04系统安装和配置（新手保姆级教程）](https://blog.csdn.net/qq_42417071/article/details/136327674)

- [Docker compose 的指定版本的安装](https://www.runoob.com/docker/docker-compose.html) ：需要保证最终使用的是V2版本

  ```shell
  # 例子
  
  # 1.下载程序
  DOCKER_COMPOSE_VERSION="v2.27.1" 
  sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  
   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                   Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  100 60.1M  100 60.1M    0     0  1964k      0  0:00:31  0:00:31 --:--:-- 2632k
  
  # 2. 设置权限
  sudo chmod +x /usr/local/bin/docker-compose
  # 3. 添加软连接（系统默认docker目录为/usr/bin/docker-compose）
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  
  # 4. 检查docker-compose 版本
  docker-compose --version
  
  Docker Compose version v2.27.1
  
  ```

- [Docker加速可用镜像及配置方法](https://blog.csdn.net/c12312303/article/details/146428465)

### 02.Git的SSH配置

- [Github配置ssh key的步骤（大白话+包含原理解释）](https://blog.csdn.net/weixin_42310154/article/details/118340458)

### 03.具体操作（示例）

> 运行过程中会有提示，选择是否使用docker启动mysql或redis，默认为是。启动后会在控制台打印mysql的root密码与redis的密码。忘记可以在docker-compose目录下的.env文件中查看

```shell
# 1.安装 git （root模式下）
sudo apt install git
# 2. git-SSH配置
ssh-keygen -t rsa -C "Github账号绑定邮箱"

# 3. 克隆本仓库

# 4. 为 sh 脚本添加可执行权限
cd nexusphp-docker/
chmod +x install.sh start.sh

# 5. 执行安装脚本
root@ubuntu:/var/nexusphp-docker# ./install.sh 
Synchronizing submodule url for 'NexusPHP'
Submodule path 'NexusPHP': checked out '64490f808f8bdbd597435dc0d0e62b635927fa18'
Previous HEAD position was 64490f80 update release date
HEAD is now at dd977403 fix exam
# 6.mysql和redis都选择y，否则需要在宿主机单独安装mysql和redis服务
Do you want to start MySQL service? [Y/n] y
Do you want to start Redis service? [Y/n] y
Root MySQL password: UJm7fqrgyQGJPbkP
Redis password: Q8VrmJwWkksvobls


# --------- 理想安装结果 start -----------------
 ✔ Network docker-compose_nexusphp-network  Created                       0.1s 
 ✔ Container pt-php                         Started                       1.5s 
 ✔ Container pt-redis                       Start...                      2.8s 
 ✔ Container pt-nginx                       Start...                      2.9s 
 ✔ Container pt-mysql                       Start...                      2.8s 
复制定时任务脚本到容器...
Successfully copied 2.56kB to pt-php:/opt/timetask.sh
Crontab entries added successfully for user www-data.
Timed task script executed successfully!
⏳ 等待 MySQL 启动（最多尝试 10 次）...
mysqladmin: [Warning] Using a password on the command line interface can be insecure.
mysqladmin: [Warning] Using a password on the command line interface can be insecure.
✅ MySQL 已启动
📦 复制 SQL 文件到容器...
Successfully copied 2.05kB to pt-mysql:/docker-entrypoint-initdb.d/install.sql
✅ SQL 文件已复制到容器路径: /docker-entrypoint-initdb.d/install.sql
🔄 重启 MySQL 容器以触发初始化...
pt-mysql
🔍 检查初始化日志...
✅ SQL 文件已触发执行
🔎 验证数据库状态...
✅ 数据库 'nexusphp' 创建成功
🎉 安装完成

root@ubuntu:/var/nexusphp-docker# docker ps
CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS          PORTS                                                                      NAMES
056b7dd795fa   nginx:alpine         "/docker-entrypoint.…"   54 seconds ago   Up 50 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp   pt-nginx
57ae9495d6cf   mysql:5.7            "docker-entrypoint.s…"   54 seconds ago   Up 43 seconds   0.0.0.0:3306->3306/tcp, :::3306->3306/tcp, 33060/tcp                       pt-mysql
320def2fee6f   redis:alpine         "docker-entrypoint.s…"   54 seconds ago   Up 50 seconds   0.0.0.0:6379->6379/tcp, :::6379->6379/tcp                                  pt-redis
21f67f802b80   docker-compose-php   "docker-php-entrypoi…"   54 seconds ago   Up 52 seconds   9000/tcp                                                                   pt-php
# --------- 理想安装结果 end -----------------

# 7. 进入pt-php容器
docker exec -it pt-php sh

# 8.切换时区
/var/www/NexusPHP # date
Wed May  7 14:25:31 UTC 2025
/var/www/NexusPHP # apk add --no-cache tzdata
fetch https://mirrors.aliyun.com/alpine/v3.21/main/x86_64/APKINDEX.tar.gz
fetch https://mirrors.aliyun.com/alpine/v3.21/community/x86_64/APKINDEX.tar.gz
(1/1) Installing tzdata (2025b-r0)
OK: 43 MiB in 74 packages
/var/www/NexusPHP # ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
/var/www/NexusPHP # echo "Asia/Shanghai" > /etc/timezone
/var/www/NexusPHP # date
Wed May  7 22:27:17 CST 2025

# 8. 执行composer install (倘若安装时间过长，可切换composer的镜像源再重新开始)
/var/www/NexusPHP # composer install

```

9.访问localhost即可进入安装过程

需要注意的是，在安装过程的第二步安装时，**注意时区选择正确**，同时请修改 **DB_HOST**与**REDIS_HOST**,如果在安装过程中选择docker启动mysql和redis，则将**DB_HOST**改为*mysql容器名（**pt-mysql**)*、**REDIS_HOST**改为*redis容器名(**pt-redis**)*，如下图：

![](./README/%E5%AE%89%E8%A3%85%E6%AD%A5%E9%AA%A42.png)

```shell
# 10.安装完成后，pt-php容器内启动定时任务
/var/www/NexusPHP # whoami
root
/var/www/NexusPHP # ps aux | grep crond
  434 root      0:00 grep crond
/var/www/NexusPHP # crontab -u www-data -l
* * * * * cd /var/www/NexusPHP && php artisan schedule:run >> /tmp/schedule_nexusphp.log
* * * * * cd /var/www/NexusPHP && php include/cleanup_cli.php >> /tmp/cleanup_cli_nexusphp.log
/var/www/NexusPHP # /usr/sbin/crond -l 0
/var/www/NexusPHP # ls -lh /var/spool/cron/crontabs/www-data
-rw-------    1 root     root         184 May  7 22:24 /var/spool/cron/crontabs/www-data
/tmp # ls -lh
total 192K   
-rw-r--r--    1 www-data www-data     342 May  7 22:36 cleanup_cli_nexusphp.log
-rwxrwxrwx    1 root     root       37.4K May  7 22:36 nexus-2025-05-07.log
-rw-r--r--    1 www-data www-data  117.5K May  7 22:31 nexus-install-20250507.log
-rw-r--r--    1 www-data www-data   12.7K May  7 22:32 nexus.log
-rw-r--r--    1 www-data www-data       0 May  7 22:36 nexus_cleanup_cli.lock
-rw-r--r--    1 www-data www-data    1.4K May  7 22:36 schedule_nexusphp.log
```

注：由于容器内默认用户是root,故而安装完毕生成的第一次日志**nexus-2025-05-07.log**，所有者为root，进一步执行 chmod 777 nexus-2025-05-07.log，否则管理系统打不开，后续的日志由PHP用户www-data决定，不存在这个问题。

## 再次启动

如果以前已经通过该脚本安装过nexusphp，但后续删除了相关容器，再此启动只需删除所有有关容器，Linux平台下运行```start.sh```即可

> 如何判断是否已经安装过？当前目录下存在log文件即代表曾经安装过.


## 目录说明
| 目录名称       | 作用       |
|-----------|-----------|
| docker-compose     | 用于存储一些可选的docker-compose.yml文件     |
| NexusPHP     | NexusPHP源码目录     | 
| nginx     | nginx配置目录     |
| data     | 数据持久化目录     | 
| log     | 日志目录     |  
| mysql     | mysql配置目录     | 

## 自定义配置
### nginx配置
修改或添加nginx目录下的内容即可，与官方nginx配置结构完全一致
### mysql配置
在mysql目录下添加*.conf文件可以

