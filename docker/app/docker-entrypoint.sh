#!/usr/bin/env bash

# Clear the cache and warm it
/var/www/html/bin/console cache:clear --no-warmup --env ${SYMFONY_ENV}
/var/www/html/bin/console cache:warmup --env ${SYMFONY_ENV}

exec "$@"
