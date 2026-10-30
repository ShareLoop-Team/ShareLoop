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

# Without an APP_KEY app setting, make one once and keep it in /home/data,
# so encrypted values and sign-in tokens survive restarts. config:cache below
# bakes it into the cached config that PHP-FPM reads.
if [ -z "$APP_KEY" ]; then
    [ -f "$DATA/app_key" ] || echo "base64:$(head -c 32 /dev/urandom | base64)" > "$DATA/app_key"
    export APP_KEY="$(cat "$DATA/app_key")"
fi

# Photo upload limits (5 MB each, 5 per item). PHP reads this file through
# the PHP_INI_SCAN_DIR app setting (/usr/local/etc/php/conf.d:/home/site/ini).
mkdir -p /home/site/ini
printf 'upload_max_filesize=6M\npost_max_size=40M\nmax_file_uploads=10\n' > /home/site/ini/shareloop.ini

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
