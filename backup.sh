#!/usr/bin/env bash

# Parameters
# Directories
backupFolder='backup';
dbBackupFolder="$backupFolder/db";
appDataBackupFolder="$backupFolder/appData";

# Colors
GREEN='\033[0;32m';
NC='\033[0m'; # No Color

# How many file keep ?
nbKeepedFiles=5;

# Header
echo '########################';
echo '## GRYC backup script ##';
echo '########################';

echo -e "\nParameters:";
echo "Backup folder: $backupFolder";
echo "Database backup folder: $dbBackupFolder";
echo -e "AppData backup folder: $appDataBackupFolder\n";

# Exit script if a command fail
set -e

# Check if script lauch as root user
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if the backup folder exists
if [ ! -d $dbBackupFolder ]; then
  mkdir -p $dbBackupFolder;
  echo -e "The folder $dbBackupFolder have been created\n";
fi

# Execute the database backup
filename=backup-`date +%Y-%m-%d_%H-%M`
echo "Database backup...";
docker exec gryc-db /usr/bin/mysqldump -u root --password=gryc gryc > $dbBackupFolder/$filename.sql
echo -e "Database backup: ${GREEN}done${NC}";
echo -e "The file $filename.sql have been created in $dbBackupFolder\n"

# Check if the backup folder exists
if [ ! -d $appDataBackupFolder ]; then
  mkdir -p $appDataBackupFolder;
  echo -e "The folder $appDataBackupFolder have been created\n";
fi

# Execute the appData backup
echo "App files backup...";
docker run --rm --volumes-from gryc-app -v $(pwd)/$appDataBackupFolder:/backup debian tar zcf /backup/$filename.tar.gz /var/www/html/files
echo -e "App files backup: ${GREEN}done${NC}";
echo -e "The file $filename.tar have been created in $appDataBackupFolder\n"

# Clean backup folder
echo "Clean backup folder...";
ls -tpd -1 $PWD/$dbBackupFolder/** | grep -v '/$' | tail -n +$((nbKeepedFiles+1)) | xargs -d '\n' -r rm --
ls -tpd -1 $PWD/$appDataBackupFolder/** | grep -v '/$' | tail -n +$((nbKeepedFiles+1)) | xargs -d '\n' -r rm --
echo -e "Clean backup folder: ${GREEN}done${NC}\n";

# Final message
echo -e "${GREEN}The backup is successfully completed";
