#!/bin/bash
# Azure App Service startup command:  bash /home/site/wwwroot/startup.sh
# Runs on every container start, before PHP-FPM takes requests.
set -e

# The database and item photos live in /home/data, which survives restarts
# and redeploys (each deploy replaces /home/site/wwwroot).
DATA=/home/data
APP=/home/site/wwwroot
mkdir -p "$DATA/private"
[ -f "$DATA/database.sqlite" ] || touch "$DATA/database.sqlite"

cd "$APP"
# Photos are on the "local" disk (storage/app/private).
rm -rf storage/app/private
ln -s "$DATA/private" storage/app/private
mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache

php artisan migrate --force
# Categories, plus the admin account when SHARELOOP_ADMIN_EMAIL/PASSWORD are
# set. Safe to repeat: it only adds or updates.
php artisan db:seed --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

cp "$APP/nginx.conf" /etc/nginx/sites-available/default
service nginx reload
