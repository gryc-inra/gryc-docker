# Docker configuration for GRYC

The project contain 3 docker-compose files:
- docker-compose.yml (used in prod and dev)
- docker-compose.override.yml (used in dev)
- docker-compose.prod.yml (used in prod)

When you are in dev, you just use the command `docker-compose build|create|up|start...`, docker-compose automatically use:
*docker-compose.yml* and *docker-compose.override.yml*.
But in production, you need manually define the files with the option`-f`: 
`docker-compose -f docker-compose.yml -f docker-compose.prod.yml build|create|up|start...`

## 1. Before install

### 1.1. Configure Elasticsearch on Server
In this Docker configuration, we used Elasticsearch, but it need we set a variable in `stsctl.conf`, else it doesn't work.

The `vm_map_max_count` setting should be set permanently in `/etc/sysctl.conf`:

    $ grep vm.max_map_count /etc/sysctl.conf
    vm.max_map_count=262144

To apply the setting on a live system type: `sysctl -w vm.max_map_count=262144`

### 1.2. Available variables

In the .env file you find all variables that permit to configure the server environment, and the app.

  1. NGINX_EXPOSED_PORT

        Define the nginx exposed port on the server, the port you need use to access to the app. 

  2. DATABASE_NAME, DATABASE_HOST, DATABASE_USER, DATABASE_PASSWORD, DATABASE_ROOT_PASSWORD

        Variables to configure the MySQL database. (You normally don't need edit DATABASE_HOST, if you do, check docker-compose.yml to adapt)

  3. ELASTICSEARCH_HOST, ELASTICSEARCH_PORT

        Idem, for elasticsearch. (You normally don't need edit it, if you do, check docker-compose.yml to adapt)

  4. RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_USER, RABBITMQ_PASSWORD

        Idem for RabbitMQ.

  5. SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD

        Configure the SMTP server, the application use a tls encryption to send mail.

  6. MAILER_SENDER_ADDRESS
  
        The email, that appear at expeditor in emails.

  7. MAILER_SENDER_NAME

        The name that appear as expeditor.

  8. SYMFONY_SECRET, SYMFONY_ENV, SYMFONY_DEBUG

        Some symfony variables that define the environment and the debug. The SYMFONY_SECRET, must be cganged and can be generated with:
        
            openssl rand -hex 20

  9. RECAPTCHA_PUBLIC_KEY, RECAPTCHA_PRIVATE_KEY

        This token are used to protect the forms in the app. You can have it on https://www.google.com/recaptcha, 
        and get an **Invisible reCAPTCHA**

## 2. How to install the Prod version

1. Clone the repository in your www folder, or in an other.

        git clone https://github.com/mpiot/gryc-docker.git gryc
        cd gryc

    The next points assume that the files are in the folder called **/var/www/gryc**.

2. Copy .env files and fill them

        cp .env.dist .env

    Then, edit the `.env` file and fill them with your data. This file has a dual purpose:
     - define vars for contruct Docker containers (like the db passwrod)
     - define vars used in the application (like the db password too)
    
3. Build images, create containers, construct network and volumes, and start created containers 

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

4. Create and populate the Elasticsearch database (may be done manually after containers started)

        docker exec -it gryc-app bin/console fos:elastica:populate

5. Configure your reverse proxy (see 4)

6. Finished

    **Your GRYC instance is ready to use!**

## 3. How to install the dev version

The installation of the dev version is similar to the prod but we don't use the same `docker-compose.yml` files, and you
need to download the source code of GRYC. We don't use volume to store it, to permit edit the code and permit change usage
per Docker.

1. Clone the repository in your workdir folder, or in an other.

        cd ~
        git clone https://github.com/mpiot/gryc.git
        git clone https://github.com/mpiot/gryc-docker.git
        cd gryc-docker

    Here we clone the gryc and the gryc-docker repositories.
 
    The points 2, 3, 4 are the same as the 2. How to install the prod version, just remove `-f` options in `docker-compose` commands.
If you want edit some ports config (eg: to access the db), edit it directly in the `docker-composer.override.yml` file.

    Follow the point 5 too, then you can configure a reverse proxy if you want too, else access your dev site on 127.0.0.1:8080
if you haven't change exposed port.

    You need to set the access rights for var/ and files/, because the app write in this folders, set the ACL like this
(do it on your server, no in the docker container):

        cd gryc
        setfacl -dR -m u:33:rwX -m u:YOUR_USERNAME:rwX var/ files/
        setfacl -R -m u:33:rwX -m u:YOUR_USERNAME:rwX var/ files/

 2. Install Yarn
   Follow the procedure: https://yarnpkg.com/lang/en/docs/install/

 3. Compile assets
 
     yarn prod|dev|watch

## 4. How to configure Haproxy

To access the site on your hostname, you need to configure a reverse proxy, that transfert traffic on the container.

An example of configuration with haproxy is available in the folder *reverse-proxy*.
Adapt the config, with the real domain name, and the port of the docker container.

You can restart haproxy whith the command:

    systemctl restart haproxy

You can access to the HaProxy management page on: http://localhost:9000/haproxy_stats (you can change it in the conf)

## 4. How to save files (Blast, EMBL, ...)

    docker run --rm --volumes-from gryc-app -v /folder/to/put/backup:/backup debian tar -zcf /backup/nom-fichier-backup.tar.gz -C /var/www/html/files .

## 5. How to dump and restore the database

To dump the database:

    docker exec gryc-db /usr/bin/mysqldump -u root --password=ROOT_PASSWORD DATABASE_NAME > backup.sql

To restore the database:

    cat backup.sql | docker exec -i gryc-db /usr/bin/mysql -u root --password=ROOT_PASSWORD DATABASE_NAME

## 6. How to install xDebug

1. Enter in the container

        docker exec -it gryc-app bash
    
2. Use the followed commands

        pecl install xdebug-2.5.0 && docker-php-ext-enable xdebug

3. Restart the container

        docker-compose restart

## 7. How to update prod version

    docker-compose -f docker-compose.yml -f docker-compose.prod.yml stop
    docker rm gryc-nginx gryc-app
    docker volume ls
    docker volume rm <APP_SRC VOLUME>
    docker pull mapiot/gryc:latest 
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
