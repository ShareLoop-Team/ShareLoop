@echo off
setlocal
title ShareLoop API
rem Starts the Laravel API on http://localhost:8000.
rem First run: installs packages, creates backend\.env and the SQLite
rem database, migrates, and adds demo data (password "password").
rem   start_backend.bat lan   -> also reachable from phones on your Wi-Fi
call "%~dp0php_env.bat" || goto :fail
cd /d "%~dp0..\backend"

if not exist vendor\autoload.php (
  echo Installing PHP packages...
  call composer install --no-interaction || goto :fail
)
if not exist .env (
  copy .env.example .env >nul
  php artisan key:generate --force || goto :fail
)
if not exist database\database.sqlite type nul > database\database.sqlite

php artisan migrate --force || goto :fail
php artisan db:seed --class=DemoSeeder --force || goto :fail

set "HOST=127.0.0.1"
if /i "%~1"=="lan" set "HOST=0.0.0.0"
echo.
echo  ShareLoop API: http://localhost:8000/api   (health check: /api/health)
echo  Demo logins: nimal@shareloop.test (admin), kavya@shareloop.test, ishara@shareloop.test - password "password"
echo  Press Ctrl+C to stop.
echo.
php artisan serve --host=%HOST% --port=8000
goto :eof

:fail
echo.
echo Something went wrong - see the messages above.
pause
exit /b 1
