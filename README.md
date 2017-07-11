# gryc-docker

First, you need to define credentials in a .env file, `cp .env.dist .env`, and edit the .env with your credentials.

If you are in production mode, use docker-compose by specifying the compose file (to avoid the usage of the docker-compose.override.yml file). To do it use a command like `docker-compose -f docker-compose.yml build|create|up -d|start`.
Else, use docker-compose normally (whithout specifying the conf file, docker automatically load both files).

In production, all is set in the .env file, because the source code of the application is in an image,
an entrypoint edit the configuration and set the credentials, the same credentials are used in docker-compose
to create containers.

In development, you need to watch the docker-compose.override.yml, as you can see, we specify some volumes:
config files (to edit it on the fly), a volume for the source code of gryc (permit you to work on the code),
more opened ports to debug, and es-head to see the Elasticsearch Index.
