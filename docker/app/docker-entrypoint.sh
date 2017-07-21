#!/usr/bin/env bash

parametersFile='app/config/parameters.yml'

# If a secret is define in env, use it, else generate a secret
if [ -n "${SYMFONY_SECRET}" ] && [ "${SYMFONY_SECRET}" != 'ThisTokenIsNotSoSecretChangeIt' ]&& [ "${SYMFONY_SECRET}" != 'null' ]
then
    sed -i -e "s/ThisTokenIsNotSoSecretChangeIt/${SYMFONY_SECRET}/g" $parametersFile
else
    sed -i -e 's/ThisTokenIsNotSoSecretChangeIt/'`openssl rand -hex 20`'/g' $parametersFile
fi

# Change all credentials
sed -i -e \
    "s/__DATABASE_NAME__/${DATABASE_NAME}/g;
    s/__DATABASE_USER__/${DATABASE_USER}/g;
    s/__DATABASE_PASSWORD__/${DATABASE_PASSWORD}/g;
    s/__RABBITMQ_USER__/${RABBITMQ_USER}/g;
    s/__RABBITMQ_PASSWORD__/${RABBITMQ_PASSWORD}/g;
    s/__MAILER_TRANSPORT__/${MAILER_TRANSPORT}/g;
    s/__MAILER_HOST__/${MAILER_HOST}/g;
    s/__MAILER_USER__/${MAILER_USER}/g;
    s/__MAILER_PASSWORD__/${MAILER_PASSWORD}/g;
    s/__RECAPTCHA_PUBLIC_KEY__/${RECAPTCHA_PUBLIC_KEY}/g;
    s/__RECAPTCHA_PRIVATE_KEY__/${RECAPTCHA_PRIVATE_KEY}/g;
    s/__APP_VERSION__/"`echo ${GRYC_VERSION} | md5sum | cut -f1 -d' '`"/g
    " $parametersFile

# Define the symfony environment
if [ "${SYMFONY_ENV}" == "prod" ]; then
    symfonyEnv = "prod";
else # dev and stage
    symfonyEnv = "dev";
fi

# Clear the cache and change authorizations
# Depend of the environment: dev or prod
/var/www/html/bin/console cache:clear --no-warmup --env $symfonyEnv
/var/www/html/bin/console cache:warmup --env $symfonyEnv

exec "$@"
