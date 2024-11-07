FROM ubuntu:latest 

ENV SYMFONY_ALLOW_ALL_IP=true 
ENV SYMFONY_LISTEN_IP=0.0.0.0

RUN apt-get update && apt-get install -y \
    php \
    php-fpm \
    composer \
    php-sqlite3 \
    php-pgsql \
    php-xml \
    php-symfony-dom-crawler \
    curl \
    postgresql-client \
    ;

RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash && \
    apt install symfony-cli

WORKDIR /symfony

RUN composer create-project symfony/symfony-demo php-app \
    --no-scripts \
    --prefer-dist \
    --no-dev \
    --no-progress \
    --no-interaction 

COPY ./app php-app

WORKDIR /symfony/php-app

RUN mkdir -p var/cache var/log var/cache/dev;

RUN COMPOSER_ALLOW_SUPERUSER=1 composer update \
    --no-scripts \
    --with-all-dependencies 

#RUN COMPOSER_ALLOW_SUPERUSER=1 composer install \
#    --no-interaction 
#RUN php bin/console sass:build

EXPOSE 8000

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
