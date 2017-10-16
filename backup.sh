#!/usr/bin/env bash

# Parameters
# Directories
backupFolder='backup';
dbBackupFolder="$backupFolder/db";
appDataBackupFolder="$backupFolder/appData";
appLogsBackupFolder="$backupFolder/appLogs";

# Colors
GREEN='\033[0;32m';
LIGHT_BLUE='\033[1;34m';
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
echo -e "App data backup folder: $appDataBackupFolder";
echo -e "App logs backup folder: $appLogsBackupFolder\n";

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

# Execute the app data backup
echo "App files backup...";
docker run --rm --volumes-from gryc-app -v $(pwd)/$appDataBackupFolder:/backup debian tar -zcf /backup/$filename.tar.gz -C /var/www/html/files .
echo -e "App files backup: ${GREEN}done${NC}";
echo -e "The file $filename.tar have been created in $appDataBackupFolder\n"

# Check if the backup folder exists
if [ ! -d $appLogsBackupFolder ]; then
  mkdir -p $appLogsBackupFolder;
  echo -e "The folder $appLogsBackupFolder have been created\n";
fi

# Execute app logs backup
echo "App logs backup...";
docker run --rm --volumes-from gryc-app -v $(pwd)/$appLogsBackupFolder:/backup debian tar -zcf /backup/$filename.tar.gz  -C /var/www/html/var/logs .
echo -e "App logs backup: ${GREEN}done${NC}";
echo -e "The file $filename.tar have been created in $appLogsBackupFolder\n"

# Clean backup folder
echo "Clean backup folder...";
ls -tpd -1 $PWD/$dbBackupFolder/** | grep -v '/$' | tail -n +$((nbKeepedFiles+1)) | xargs -d '\n' -r rm --
echo -e "Clean db backups: ${LIGHT_BLUE}done${NC}";
ls -tpd -1 $PWD/$appDataBackupFolder/** | grep -v '/$' | tail -n +$((nbKeepedFiles+1)) | xargs -d '\n' -r rm --
echo -e "Clean app data backups: ${LIGHT_BLUE}done${NC}";
ls -tpd -1 $PWD/$appLogsBackupFolder/** | grep -v '/$' | tail -n +$((nbKeepedFiles+1)) | xargs -d '\n' -r rm --
echo -e "Clean app logs backups: ${LIGHT_BLUE}done${NC}";
echo -e "Clean backup folder: ${GREEN}done${NC}\n";

# Final message
echo -e "${GREEN}The backup is successfully completed${NC}";
