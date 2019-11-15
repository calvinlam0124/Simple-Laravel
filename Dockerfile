# docker run --rm -it -p 8080:8080 calvin-simple-laravel bash
# docker build -t calvin-simple-laravel .
# docker tag calvin-simple-laravel calvinlam/simple-laravel
# docker push calvinlam/simple-laravel

# FROM composer:1.9.1 as phpcomposer
# WORKDIR /var/www/html
# COPY . /var/www/html
# RUN set -xe \
#  && composer global require hirak/prestissimo \
#  && composer install --no-dev --no-scripts --no-suggest --no-interaction --prefer-dist --optimize-autoloader --ignore-platform-reqs \
#  && composer dump-autoload --optimize --classmap-authoritative
# RUN composer install

FROM php:7.3.11-apache
WORKDIR /var/www/html
COPY . /var/www/html
# COPY --from=phpcomposer /var/www/html/vendor /var/www/html/vendor

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


# config apache2
RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
ENV PORT 8080
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf


# xdebug
RUN apt-get update &&\
    apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git &&\
    rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug && docker-php-ext-enable xdebug

# Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === trim(file_get_contents('https://composer.github.io/installer.sig'))) { echo 'Installer verified'; } else { echo 'Installer invalid'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && php composer.phar global require hirak/prestissimo \
    && php composer.phar install

# config laravel
RUN chmod 777 storage/logs \
  && chmod 777 storage/framework/sessions \
  && chmod 777 storage/framework/views
