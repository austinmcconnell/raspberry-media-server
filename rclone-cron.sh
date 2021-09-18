#!/bin/bash
if pidof -o %PPID -x “rclone-cron.sh”; then
exit 1
fi
rclone copy /opt/appdata/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml remote:raspberry-pi-backup/appdata/plex/ --progress
rclone copy /opt/appdata/letsencrypt remote:raspberry-pi-backup/appdata/letsencrypt --copy-links --progress
exit
