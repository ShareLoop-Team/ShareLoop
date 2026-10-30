# ShareLoop API (Laravel)

The backend for the ShareLoop Flutter app: a JSON REST API built with
**Laravel 13** and **Sanctum** API tokens. It handles accounts and sign-in,
give-away posts with photos, requests, the handover workflow, ratings,
reports and admin moderation. The full API and the rules it enforces are
in [`../doc/BACKEND.md`](../doc/BACKEND.md).

## Run it (Windows)

Needs PHP 8.3+ (`winget install PHP.PHP.8.3`). Composer is downloaded
automatically.

```bat
tool\start_backend.bat
```

From the repo root. The first run installs packages, creates `backend\.env`
and `database\database.sqlite`, migrates, and adds demo data. The API is then on
**http://localhost:8000/api** (try `/api/health`). Then run the app:
`tool\run_app_chrome.bat` (Chrome) or `tool\run_app_web.bat` (any browser at
http://localhost:5000).

Demo accounts (password `password`): `nimal@shareloop.test` (admin),
`kavya@shareloop.test`, `ishara@shareloop.test`.

Using the Android emulator: set `API_BASE_URL=http://10.0.2.2:8000/api` in the
repo's `.env`. A real phone on the same Wi-Fi: `tool\start_backend.bat lan` and
`API_BASE_URL=http://<your PC's IP>:8000/api` (allow PHP through Windows
Firewall when asked).

## Run it (any OS, by hand)

```bash
cd backend
composer install
cp .env.example .env && php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed                      # categories (+ admin from .env)
php artisan db:seed --class=DemoSeeder          # optional demo data
php artisan serve                               # http://localhost:8000
```

PHP extensions needed: `pdo_sqlite` (or `pdo_mysql`), `mbstring`, `openssl`,
`fileinfo`, `curl`, `zip`, `gd`. The Windows scripts enable these in their
own `php.ini` (`%LOCALAPPDATA%\ShareLoop\php.ini`) without touching your PHP
install.

## Tests

```bash
php artisan test          # or: tool\check_all.bat (backend + Flutter)
```

41 feature tests covering sign-up/login/reset, who can see what (contact
details, private requests, hidden posts), every handover rule, photos,
ratings, reports and admin moderation. They use an in-memory SQLite
database and a fake disk, so they don't touch your data.

## MySQL instead of SQLite

In `backend/.env`:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=shareloop
DB_USERNAME=root
DB_PASSWORD=...
```

Create the `shareloop` database first, then `php artisan migrate --seed`.

## Useful commands

| Command | Does |
|---|---|
| `php artisan shareloop:make-admin you@example.com` | give an account admin rights (`--revoke` to remove) |
| `php artisan migrate:fresh --seed` | wipe and recreate the database (dev only) |
| `php artisan route:list --path=api` | list the endpoints |
| `php artisan pail` | follow the log (reset-password emails land there with `MAIL_MAILER=log`) |

## Where things are

| Path | What |
|---|---|
| `routes/api.php` | every endpoint |
| `app/Http/Controllers/Api/` | request handling and validation |
| `app/Services/ExchangeService.php` | select requester → confirm → complete / cancel, ratings (transactions + row locks) |
| `app/Services/PhotoStorage.php` | photo files and signed URLs |
| `app/Http/Resources/` | JSON shapes the app reads (contacts hidden unless allowed) |
| `app/Models/` | Eloquent models and visibility scopes |
| `config/shareloop.php` | districts, conditions, categories, photo limits, page sizes |
| `database/migrations/` | schema |
| `database/seeders/` | categories, optional admin, demo data |
| `resources/views/auth/reset-password.blade.php` | page the reset email links to |
| `tests/Feature/` | the test suite |

## Deploying

Any PHP 8.3 host works (Azure App Service, a VPS, etc.): set `APP_ENV=production`,
`APP_DEBUG=false`, `APP_URL=https://your-domain`, real `DB_*` and `MAIL_*`
values, run `composer install --no-dev --optimize-autoloader`,
`php artisan migrate --force`, `php artisan config:cache route:cache`, and point
the web server at `public/`. Keep `storage/` writable and persistent (photos
live in `storage/app/private`). Build the app with
`API_BASE_URL=https://your-domain/api`.
