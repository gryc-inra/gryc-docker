#!/usr/bin/env bash

# Clear the cache and warm it
/var/www/html/bin/console cache:clear --no-warmup --env ${SYMFONY_ENV}
/var/www/html/bin/console cache:warmup --env ${SYMFONY_ENV}

# Add a sleep, because sessions folder is created 10-20 seconds after php-fpm init
sleep 10

# Re-define the user
chown -R www-data:www-data /var/www/html/var
