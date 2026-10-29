@echo off
setlocal EnableDelayedExpansion
title ShareLoop checks
rem Backend tests, then Flutter analyze + tests. Results also go to
rem tool\check_all.log.
set "LOG=%~dp0check_all.log"
call "%~dp0php_env.bat" || goto :eof
cd /d "%~dp0..\backend"
(
echo === backend tests
php artisan config:clear
php vendor/bin/phpunit --colors=never
echo === backend exit !ERRORLEVEL!
cd /d "%~dp0.."
echo === flutter pub get
call flutter pub get
echo === flutter analyze
call flutter analyze
echo === analyze exit !ERRORLEVEL!
echo === flutter test
call flutter test
echo === test exit !ERRORLEVEL!
echo === DONE
) > "%LOG%" 2>&1
type "%LOG%"
pause
