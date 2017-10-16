#!/usr/bin/env bash

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Exit script if a command fail
set -e

# Check if script launch as root user
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Build new images
echo "Build images...";
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build
echo -e "Build images: ${GREEN}done${NC}\n";

# Show the maintenance page
echo "Display maintenance page...";
mv maintenance-off.html maintenance-on.html
echo -e "Display maintenance page: ${GREEN}done${NC}\n";

# Stop containers
echo "Stop containers...";
docker-compose -f docker-compose.yml -f docker-compose.prod.yml stop
echo -e "Stop containers: ${GREEN}done${NC}\n";

# Delete app and nginx containers
echo "Delete containers...";
docker rm gryc-nginx gryc-app
echo -e "Delete containers: ${GREEN}done${NC}\n";

# Delete gryc_app_src volume
echo "Delete volume...";
docker volume rm gryc_app_src
echo -e "Delete volume: ${GREEN}done${NC}\n";

# Create new containers
echo "Create containers...";
docker-compose -f docker-compose.yml -f docker-compose.prod.yml create
echo -e "Create containers: ${GREEN}done${NC}\n";

# Up containers
echo "Up containers...";
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
echo -e "Up containers: ${GREEN}done${NC}\n";

# Wait all containers are correctly started
echo -e "Wait for all containers completly started...\n";
secs=$((20))
while [ $secs -gt 0 ]; do
   echo -ne "$secs\033[0K\r"
   sleep 1
   : $((secs--))
done

# Hide the maintenance page
echo "Hide maintenance page...";
mv maintenance-on.html maintenance-off.html
echo -e "Hide maintenance page: ${GREEN}done${NC}\n";
