# Docker configuration for GRYC

The project contain 3 docker-compose files:
- docker-compose.yml (used in prod and dev)
- docker-compose.override.yml (used in dev)
- docker-compose.prod.yml (used in prod)

When you are in dev, you just use the command `docker-compose build|create|up|start...`, docker-compose automatically use *docker-compose.yml* and *docker-compose.override.yml*.
But in production, you need manually define the files with `-f`: `docker-compose -f docker-compose.yml -f docker-compose.prod.yml build|create|up|start...`

## 1. List of Environment variables used by the app

You can set all informations: login, passwords, api key, etc... In the .env files in the folder docker.
You may copy all *\*.env.dist* to *\*.env*, and edit the new files.

### app.env

1. DATABASE_URL

    This is the URL to connect the application to the MYSQL database (eg: mysql://login:password@host:port/databaseName)

2. ELASTICSEARCH_URL

    The URL to connect the app to ElasticSearch (the searcheable database) (eg: http://host:port)

3. RABBITMQ_URL

    The URL to connect the app to the Queuing service (eg: amqp://login:password@host:port/vhost?lazy=1&connection_timeout=3&read_write_timeout=3)

4. MAILER_URL

    The URL use by the app to send email, here an exemple of an smtp connection (eg: smtp://login:password@host?encryption=ssl&auth_mode=login)

5. MAILER_SENDER_ADDRESS and MAILER_SENDER_NAME

    This variables are used by the app when it send email (define the sender mail and name, and used in contact us to send you the mail)

6. SYMFONY_SECRET

    This is a token of 40 chars, you can generate it with this command: `openssl rand -hex 20`

7. RECAPTCHA_PUBLIC_KEY and RECAPTCHA_PRIVATE_KEY

    This token are used to protect the forms in the app.
    You can have it on https://www.google.com/recaptcha, and get an 'Invisible reCAPTCHA'

### db.env

1. MYSQL_ROOT_PASSWORD

    Set the root password of the mariadb server

2. MYSQL_USER

    Set the user used by the app (you need use the same in the .env above: DATABASE_URL)

3. MYSQL_PASSWORD

    Set the password used by the app (you need use the same in the .env above: DATABASE_URL)

4. MYSQL_DATABASE

    Set the database name used by the app (you need use the same in the .env above: DATABASE_URL)

### rabbitmq.env

1. RABBITMQ_DEFAULT_VHOST

    Set the RabbitMq Vhost (you need use the same in the .env above: RABBITMQ_URL)

2. RABBITMQ_DEFAULT_USER

    Set the RabbitMq user (you need use the same in the .env above: RABBITMQ_URL)

3. RABBITMQ_DEFAULT_PASS

    Set the RabbitMq password (you need use the same in the .env above: RABBITMQ_URL)

## 2. Before install

### 2.1. Configure Elasticsearch on Server
In this Docker configuration, we used Elasticsearch, but it need we set a variable in stsctl.conf, else it doesn't work.

The vm_map_max_count setting should be set permanently in /etc/sysctl.conf:

    $ grep vm.max_map_count /etc/sysctl.conf
    vm.max_map_count=262144
    
To apply the setting on a live system type: `sysctl -w vm.max_map_count=262144`

## 3. How to install

1. Clone the repository

        cd /var/www
        git clone https://github.com/mpiot/gryc-docker.git gryc

The next points assume that the files are in the folder called **/var/www/gryc**.

2. Copy .env files and fill them

    cd gryc/docker
    cp app.env.dist app.env && cp db.env.dist db.env && cp rabbitmq.env.dist rabbitmq.env

Then, edit the .env files and fill them with your data (see **1. List of Environment variables used by the app**)

3. Build images

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml build
    
4. Create containers, construct network and volumes, and start created containers 

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

5. Configure your reverse proxy

    An example of configuration with nginx is available in the folder *reverse-proxy*.

    If you use it, keep in mind to do a link from site-available to site-enable, then reload the configuration:

        ln -s /etc/nginx/site-available/gryc /etc/nginx/site-enable/gryc
        systemctl reload nginx

## 4. After install

### 4.1. In Dev and Prod

#### 4.1.1. Set database schema
The project use a SQL database, then you must init it:

    docker exec -it gryc-app bin/console doctrine:schema:update --force

#### 4.1.2. Init the Elasticsearch database
The same thing for Elasticsearch:

    docker exec -it gryc-app bin/console fos:elastica:populate

### 4.2. In Dev only
You need to set the access rights for var/ and files/, because the app write in this folders, set the ACL like this:

    # setfacl -dR -m u:33:rwX -m u:YOUR_USERNAME:rwX var/ files/
    # setfacl -R -m u:33:rwX -m u:YOUR_USERNAME:rwX var/ files/

## 5. How to update and backup

You can find scripts in mpiot/docker-scripts github project

## 7. How to dump and restore the database

To dump the database:

    docker exec gryc-db /usr/bin/mysqldump -u root --password=ROOT_PASSWORD DATABASE_NAME > backup.sql

To restore the database:

    cat backup.sql | docker exec -i gryc-db /usr/bin/mysql -u root --password=ROOT_PASSWORD DATABASE_NAME

## 8. How to install xDebug

1. Enter in the container

        docker exec -it gryc-app bash
    
2. Use the followed commands

        pecl install xdebug-2.5.0 && docker-php-ext-enable xdebug

3. Restart the container

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart
