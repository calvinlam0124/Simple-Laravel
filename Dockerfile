# docker build -t localhost-simple-laravel .
# docker run --rm -it -p 80:80 localhost-simple-laravel bash
# CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]


FROM composer:1.9.1 as phpcomposer
WORKDIR /var/www/html
COPY . /var/www/html
RUN set -xe \
 && composer global require hirak/prestissimo \
 && composer install --no-dev --no-scripts --no-suggest --no-interaction --prefer-dist --optimize-autoloader --ignore-platform-reqs \
 && composer dump-autoload --optimize --classmap-authoritative
# RUN ls -alF > vendor/ls_alf.txt


FROM php:7.3.11-apache
WORKDIR /var/www/html
COPY . /var/www/html
COPY --from=phpcomposer /var/www/html/vendor /var/www/html/vendor
# COPY --from=phpcomposer /app/composer.json /var/www/html/.
# COPY --from=phpcomposer /app/composer.lock /var/www/html/.

# git: for php package barryvdh/laravel-debugbar
# zip, unzip: for composer download from dist
# libmagickwand-dev: for intervention/image and php7-imagick
# ssh: ssh client for git-ssh
RUN apt-get update && apt-get install -y \
        $PHPIZE_DEPS \
        ca-certificates \
        curl \
        xz-utils \
        git \
        zip unzip\
        libzip-dev \
        libmagickwand-dev \
        ssh \
        --no-install-recommends && rm -r /var/lib/apt/lists/*

# imagick: for intervention/image
RUN pecl install imagick

# pdo_mysql, bcmath: officail laravel requirement
# fileinfo, imagick: for php package intervention/image
RUN docker-php-ext-install pdo_mysql bcmath zip gd
RUN docker-php-ext-enable imagick


RUN a2enmod rewrite

COPY apache2.000-default.conf /etc/apache2/sites-enabled/000-default.conf

# xdebug
RUN apt-get update &&\
    apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git &&\
    rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug && docker-php-ext-enable xdebug


# config laravel
RUN chmod 777 storage/logs \
  && chmod 777 storage/framework/sessions \
  && chmod 777 storage/framework/views
