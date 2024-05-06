# 定义构建参数
ARG PHP_VERSION=8.3
ARG COMPOSER_VERSION=latest

# 使用 composer 镜像作为构建阶段的基础镜像
FROM composer:${COMPOSER_VERSION} AS vendor

# 使用 php 镜像作为基础镜像
FROM php:${PHP_VERSION}-cli-bookworm AS base

# 定义构建参数
ARG WWWUSER=1000
ARG WWWGROUP=1000
ARG TZ=Asia/Shanghai

# 设置镜像标签
LABEL authors="abrahamgreyson"
LABEL wechat="abrahamgreyson"
LABEL org.opencontainers.image.title="Laravel Octane Dockerfile"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
  TERM=xterm-color \
  WITH_HORIZON=false \
  WITH_SCHEDULER=false \
  OCTANE_SERVER=swoole \
  USER=octane \
  ROOT=/var/www/html \
  COMPOSER_FUND=0 \
  COMPOSER_MAX_PARALLEL_HTTP=24 \
  WORKER_COMMAND="php artisan queue:work" \

# 设置工作目录
WORKDIR ${ROOT}

# 设置 shell
SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

# 设置时区
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo ${TZ} > /etc/timezone

# 添加 PHP 扩展安装脚本
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# 更新系统并安装必要的软件包和 PHP 扩展
RUN apt-get update; \
  apt-get upgrade -yqq; \
  apt-get install -yqq --no-install-recommends --show-progress \
  apt-utils \
  curl \
  wget \
  nano \
  ncdu \
  ca-certificates \
  supervisor \
  libsodium-dev \
  && install-php-extensions \
  bz2 \
  pcntl \
  mbstring \
  bcmath \
  sockets \
  pgsql \
  pdo_pgsql \
  opcache \
  exif \
  pdo_mysql \
  zip \
  intl \
  gd \
  redis \
  rdkafka \
  memcached \
  igbinary \
  ldap \
  swoole \
  && apt-get -y autoremove \
  && apt-get clean \
  && docker-php-source delete \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && rm /var/log/lastlog /var/log/faillog

# 安装 supercronic 并设置 Laravel 的计划任务
RUN wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64" \
  -O /usr/bin/supercronic \
  && chmod +x /usr/bin/supercronic \
  && mkdir -p /etc/supercronic \
  && echo "*/1 * * * * php ${ROOT}/artisan schedule:run --no-interaction" > /etc/supercronic/laravel

# 创建新的用户和用户组
RUN userdel --remove --force www-data \
  && groupadd --force -g ${WWWGROUP} ${USER} \
  && useradd -ms /bin/bash --no-log-init --no-user-group -g ${WWWGROUP} -u ${WWWUSER} ${USER}

# 更改文件和目录的所有权
RUN chown -R ${USER}:${USER} ${ROOT} /var/{log,run} \
  && chmod -R a+rw ${ROOT} /var/{log,run}

# 复制 PHP 配置文件
RUN cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

# 切换到新用户
USER ${USER}

# 从 vendor 阶段复制 composer 到当前镜像
COPY --chown=${USER}:${USER} --from=vendor /usr/bin/composer /usr/bin/composer
COPY --chown=${USER}:${USER} composer.json composer.lock ./

# 安装 composer 依赖
# 如果 php 8.2 以上这里加个审计 audit
RUN composer install \
  --no-dev \
  --no-interaction \
  --no-autoloader \
  --no-ansi \
  --no-scripts


RUN composer --version

# 复制项目文件到当前镜像
COPY --chown=${USER}:${USER} . .

# 创建必要的目录并设置权限
RUN mkdir -p \
  storage/framework/{sessions,views,cache,testing} \
  storage/logs \
  bootstrap/cache && chmod -R a+rw storage

# 复制 supervisord 配置文件和 PHP 配置文件到当前镜像
COPY --chown=${USER}:${USER} deployment/supervisord.*.conf /etc/supervisor/conf.d/
COPY --chown=${USER}:${USER} deployment/php.ini ${PHP_INI_DIR}/conf.d/99-octane.ini
COPY --chown=${USER}:${USER} deployment/start-container /usr/local/bin/start-container

# 安装 composer 依赖并清理缓存
RUN composer install \
  --classmap-authoritative \
  --no-interaction \
  --no-ansi \
  --no-dev \
  && composer clear-cache \
  && php artisan storage:link

# 设置 start-container 脚本的执行权限
RUN chmod +x /usr/local/bin/start-container

# 添加 utilities.sh 到 bashrc
# RUN cat deployment/utilities.sh >> ~/.bashrc

# 暴露 80 端口
EXPOSE 80

# 设置容器启动命令
ENTRYPOINT ["start-container"]

# 设置健康检查命令
HEALTHCHECK --start-period=5s --interval=2s --timeout=5s --retries=8 CMD php artisan octane:status || exit 1
