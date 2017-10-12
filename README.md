# Docker configuration for GRYC

If you are in production mode, use docker-compose by specifying the compose file to avoid the usage of the docker-compose.override.yml file
and use docker-compose.prod.yml. To do it use a command like `docker-compose -f docker-compose.yml -f docker-compose.prod.yml build|create|up -d|start`.
Else, use docker-compose normally (whithout specifying the conf file, docker automatically load both files).

## 1. List of Environment variables used by the app

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

8. SYMFONY_ENV

    Used for clear and warmup the cache.

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

Assuming that the files are in a folder called **gryc**, and you have read the introduction to correctly define the docker-compose files.

2. Build images

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

3. Create containers

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml create
    
4. Start new containers and reconstruct the gryc_app_src

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

5. Configure your nginx (used at reverse proxy)

        vi /etc/nginx/nginx.conf

    In this file, add the following lines:
    
        server {
            listen       80;
            server_name  gryc.test;
            
            location / {
                if (-f /var/www/gryc/maintenance-on.html) {
                return 503;
            }
            
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://localhost:8080;
            }
            
            error_page 503 @maintenance;
            location @maintenance {
                root /var/www/gryc/;
                rewrite ^(.*)$ /maintenance-on.html break;
            }
        }

    In this file:
    - the website url is gryc.test
    - the nginx docker container listen on 8080 (proxy_pass http://localhost:8080;)

## 4. After install

### 4.1. In Dev and Prod

#### 4.1.1. Set database schema
The project use a SQL database, then you must init it:

    $ bin/console doctrine:schema:update --force

#### 4.1.2. Init the Elasticsearch database
The same thing for Elasticsearch:

    $ bin/console fos:elastica:populate

### 4.2. In Dev only
You need to set the access rights for var/ and files/, because the app write in this folders, set the ACL like this:

    # setfacl -dR -m u:33:rwX -m u:YOUR_USERNAME:rwX var/ files/
    # setfacl -R -m u:33:rwX -m u:YOUR_USERNAME:rwX var/ files/

## 5. How to update

If you have followed the installation procedure, you just have to use the update.sh bash script.

## 6. How to backup ?

Use the backup.sh script to perform a database and appData backup.

## 7. How to dump and restore the database

To dump the database:

    docker exec CONTAINER /usr/bin/mysqldump -u root --password=root DATABASE > backup.sql

To restaure the database:

    cat backup.sql | docker exec -i CONTAINER /usr/bin/mysql -u root --password=root DATABASE

## 8. How to install xDebug

1. Enter in the container

        docker exec -it gryc-app bash
    
2. Use the followed commands

        pecl install xdebug-2.5.0 && docker-php-ext-enable xdebug

3. Restart the container

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart
