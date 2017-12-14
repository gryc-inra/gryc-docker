# Docker configuration for GRYC

The project contain 3 docker-compose files:
- docker-compose.yml (used in prod and dev)
- docker-compose.override.yml (used in dev)
- docker-compose.prod.yml (used in prod)

When you are in dev, you just use the command `docker-compose build|create|up|start...`, docker-compose automatically use *docker-compose.yml* and *docker-compose.override.yml*.
But in production, you need manually define the files with `-f`: `docker-compose -f docker-compose.yml -f docker-compose.prod.yml build|create|up|start...`

## 1. Before install

### 1.1. Configure Elasticsearch on Server
In this Docker configuration, we used Elasticsearch, but it need we set a variable in stsctl.conf, else it doesn't work.

The vm_map_max_count setting should be set permanently in /etc/sysctl.conf:

    $ grep vm.max_map_count /etc/sysctl.conf
    vm.max_map_count=262144
    
To apply the setting on a live system type: `sysctl -w vm.max_map_count=262144`

## 2. How to install

1. Clone the repository

        cd /var/www
        git clone https://github.com/mpiot/gryc-docker.git gryc

The next points assume that the files are in the folder called **/var/www/gryc**.

2. Copy .env files and fill them

    cp .env.dist .env

Then, edit the .env file and fill them with your data

3. Build images

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml build
    
4. Create containers, construct network and volumes, and start created containers 

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

5. Configure your reverse proxy

    An example of configuration with nginx is available in the folder *reverse-proxy*.

    If you use it, keep in mind to do a link from site-available to site-enable, then reload the configuration:

        ln -s /etc/nginx/site-available/gryc /etc/nginx/site-enable/gryc
        systemctl reload nginx

## 3. After install

### 3.1. In Dev and Prod

#### 3.1.1. Set database schema
The project use a SQL database, then you must init it:

    docker exec -it gryc-app bin/console doctrine:schema:update --force

#### 3.1.2. Init the Elasticsearch database
The same thing for Elasticsearch:

    docker exec -it gryc-app bin/console fos:elastica:populate

### 3.2. In Dev only
You need to set the access rights for var/ and files/, because the app write in this folders, set the ACL like this:

    # setfacl -dR -m u:33:rwX -m u:YOUR_USERNAME:rwX var/ files/
    # setfacl -R -m u:33:rwX -m u:YOUR_USERNAME:rwX var/ files/

## 4. How to update and backup

You can find scripts in mpiot/docker-scripts github project

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

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart
