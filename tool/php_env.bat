@echo off
rem Shared by the ShareLoop scripts: finds PHP, enables the extensions
rem Laravel needs (in a php.ini of our own, so your PHP install is left
rem alone), and makes "composer" available. Call it, don't run it.
set "SL_TOOLS=%LOCALAPPDATA%\ShareLoop"
if not exist "%SL_TOOLS%" mkdir "%SL_TOOLS%"
set "SL_PHPEXE="
for /f "delims=" %%p in ('where php 2^>nul') do if not defined SL_PHPEXE set "SL_PHPEXE=%%p"
if not defined SL_PHPEXE (
  echo PHP 8.3+ was not found. Install it with:  winget install PHP.PHP.8.3
  exit /b 1
)
for %%d in ("%SL_PHPEXE%") do set "SL_PHPDIR=%%~dpd"
rem Trusted certificates for HTTPS calls (Google sign-in keys, Facebook):
rem the one that comes with PHP, else Git for Windows' bundle.
set "SL_CA="
if exist "%SL_PHPDIR%cacert.pem" set "SL_CA=%SL_PHPDIR%cacert.pem"
if not defined SL_CA if exist "%ProgramFiles%\Git\mingw64\etc\ssl\certs\ca-bundle.crt" set "SL_CA=%ProgramFiles%\Git\mingw64\etc\ssl\certs\ca-bundle.crt"
if not defined SL_CA echo Warning: no CA certificate bundle found; Google and Facebook sign-in will fail.
(
if defined SL_CA echo curl.cainfo="%SL_CA%"
if defined SL_CA echo openssl.cafile="%SL_CA%"
echo extension_dir="%SL_PHPDIR%ext"
echo extension=curl
echo extension=fileinfo
echo extension=mbstring
echo extension=openssl
echo extension=pdo_mysql
echo extension=pdo_sqlite
echo extension=sqlite3
echo extension=zip
echo extension=gd
echo memory_limit=1G
echo upload_max_filesize=6M
echo post_max_size=40M
echo max_file_uploads=10
) > "%SL_TOOLS%\php.ini"
set "PHPRC=%SL_TOOLS%"
if not exist "%SL_TOOLS%\composer.phar" (
  echo Downloading Composer...
  php -r "copy('https://getcomposer.org/download/latest-stable/composer.phar', getenv('SL_TOOLS').'\\composer.phar');"
)
> "%SL_TOOLS%\composer.bat" echo @php "%%~dp0composer.phar" %%*
set "PATH=%SL_TOOLS%;%PATH%"
exit /b 0
