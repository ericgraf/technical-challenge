#!/usr/bin/env bash

#TODO: move this back to the main dockerfile
# this is here because we pass in db info as ENV variables
COMPOSER_ALLOW_SUPERUSER=1 composer install \
    --no-interaction

php bin/console sass:build
php bin/console importmap:install

#TODO only run this on dev and only once
# For interest time we will let this run each time
php bin/console doctrine:database:create
php bin/console doctrine:schema:create
php bin/console doctrine:fixtures:load

/usr/bin/symfony server:start
