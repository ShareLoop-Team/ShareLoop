@echo off
setlocal EnableDelayedExpansion
title ShareLoop backend tests
rem Runs the Laravel test suite. Output also goes to tool\test_backend.log.
call "%~dp0php_env.bat" || goto :eof
cd /d "%~dp0..\backend"
(
php artisan config:clear
php vendor/bin/phpunit --colors=never
echo === exit !ERRORLEVEL!
echo === DONE
) > "%~dp0test_backend.log" 2>&1
type "%~dp0test_backend.log"
timeout /t 15
