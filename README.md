# Docker configuration for GRYC

If you are in production mode, use docker-compose by specifying the compose file to avoid the usage of the docker-compose.override.yml file
and use docker-compose.prod.yml. To do it use a command like `docker-compose -f docker-compose.yml -f docker-compose.prod.yml build|create|up -d|start`.
Else, use docker-compose normally (whithout specifying the conf file, docker automatically load both files).

In production, all is set in the .env file, because the source code of the application is in an image,
an entrypoint edit the configuration and set the credentials, the same credentials are used in docker-compose
to create containers.

In development, you need to watch the docker-compose.override.yml, as you can see, we specify some volumes:
config files (to edit it on the fly), a volume for the source code of gryc (permit you to work on the code),
more opened ports to debug, and es-head to see the Elasticsearch Index.

## List of Environment variables used by the app

1. DATABASE_URL

    This is the URL to connect the application to the MYSQL database (eg: mysql://login:password@host:port/databaseName)

2. REDIS_DSN

    The domaine service name, to connect the app to the Redis service (eg: redis://host)

3. ELASTICSEARCH_URL

    The URL to connect the app to ElasticSearch (the searcheable database) (eg: http://host:port)

4. RABBITMQ_URL

    The URL to connect the app to the Queuing service (eg: amqp://login:password@host:port/vhost?lazy=1&connection_timeout=3&read_write_timeout=3)

5. MAILER_URL

    The URL use by the app to send email, here an exemple of an smtp connection (eg: smtp://login:password@host?encryption=ssl&auth_mode=login)

6. MAILER_SENDER_ADDRESS and MAILER_SENDER_NAME

    This variables are used by the app when it send email (define the sender mail and name, and used in contact us to send you the mail)

7. SYMFONY_SECRET

    This is a token of 40 chars, you can generate it with this command: `openssl rand -hex 20`

8. RECAPTCHA_PUBLIC_KEY and RECAPTCHA_PRIVATE_KEY

    This token are used to protect the forms in the app.
    You can have it on https://www.google.com/recaptcha, and get an 'Invisible reCAPTCHA'

9. SYMFONY_ENV

    Used for clear and warmup the cache.

## How to install

Assuming that the files are in a folder called **gryc**, and you have read the introduction to correctly define the docker-compose files.

1. Build images

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

2. Create containers

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml create
    
6. Start new containers and reconstruct the gryc_app_src

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

## How to update

Assuming that you followed the installation above.

1. Build new images

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

2. Stop containers

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml stop

3. Delete app and nginx containers

    docker rm gryc-nginx gryc-app

7. Delete gryc_app_src volume

    docker volume rm gryc_app_src

5. Create new containers

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml create

6. Start new containers and reconstruct the gryc_app_src

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

## How to install xDebug

1. Enter in the container

    docker exec -it gryc-app bash
    
2. Use the followed commands

    pecl install xdebug-2.5.0 && docker-php-ext-enable xdebug

3. Restart the container

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart
