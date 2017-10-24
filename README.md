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

### 2.2. Copy .env files and fill them

    cd docker
    cp app.env.dist app.env && cp db.env.dist db.env && cp rabbitmq.env.dist rabbitmq.env

Then, edit the .env files and fill them with your data (see **1. List of Environment variables used by the app**)

## 3. How to install

1. Clone the repository

        cd /var/www
        git clone https://github.com/mpiot/gryc-docker.git gryc

The next points assume that the files are in the folder called **/var/www/gryc**.

2. Build images

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml build
    
3. Start new containers and construct network and volumes

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

4. Configure your reverse proxy

        vi /etc/nginx/site-available/gryc

    In this file, add the following lines:

        # HTTP/1.1 connexion (redirect on https)
        server {
            listen      80;
            server_name gryc.dev;

            # Redirect the http flux to https (301: Permanent redirection)
            return 301 https://gryc.dev$request_uri;
        }

        # HTTP/2 or HTTP/1.1 over SSL connexion
        server {
            listen      443 ssl http2;
            server_name gryc.dev;

            # SSL configuration
            ssl_certificate     /etc/nginx/ssl/gryc.crt;
            ssl_certificate_key /etc/nginx/ssl/gryc.key;

            # SSL optimizations

            # Session Caching
            ssl_session_cache shared:SSL:20m;
            ssl_session_timeout 4h;

            # Session Tickets and IDs
            ssl_session_tickets on;

            # Secure
            add_header X-Frame-Options DENY;
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";

            # Block WordPress Pingback DDoS attacks
            #if ($http_user_agent ~* "WordPress") {
            #  return 403;
            #}

            location / {
                # Test exixtance of a page, if exist: return 503 error
                if (-f /home/mpiot/Development/gryc-docker/maintenance-on.html) {
                    return 503;
                }

                # Set the reverse proxy, to redirect http request to the Docker server
                proxy_pass          http://127.0.0.1:8080;
                proxy_set_header    Host                $host;
                proxy_set_header    X-Real-IP           $remote_addr;
                proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
                proxy_set_header    X-Forwarded-SSL     on;
                proxy_set_header    X-Forwarded-Proto   $scheme;
            }

            # Set the 503 code: Service Unavailable (Service temporarily unavailable or in maintenance.)
            error_page 503 @maintenance;
            location @maintenance {
                root    /home/mpiot/Development/gryc-docker;
                rewrite ^(.*)$ /maintenance-on.html break;
            }
        }

    In this file:
    - we use http2 and ssl
    - the website url is gryc.dev
    - the nginx docker container listen on 8080

5. Enable the host and restart nginx

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

## 5. How to update

If you have followed the installation procedure, you just have to use the update.sh bash script as root: `./update.sh`

## 6. How to backup ?

Use the backup.sh script asroot to perform a database, appData, and appLogs: `./backup.sh`

## 7. How to dump and restore the database

To dump the database:

    docker exec CONTAINER /usr/bin/mysqldump -u root --password=root DATABASE > backup.sql

To restore the database:

    cat backup.sql | docker exec -i CONTAINER /usr/bin/mysql -u root --password=root DATABASE

## 8. How to install xDebug

1. Enter in the container

        docker exec -it gryc-app bash
    
2. Use the followed commands

        pecl install xdebug-2.5.0 && docker-php-ext-enable xdebug

3. Restart the container

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart
