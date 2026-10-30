<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Console\ServeCommand;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // `php artisan serve` only hands a short list of environment variables
        // to the PHP server it starts. Without TEMP/TMP, PHP on Windows can't
        // store uploads ("unable to create a temporary file"), and without
        // PHPRC it ignores the php.ini our tool scripts set up.
        ServeCommand::$passthroughVariables = array_values(array_unique([
            ...ServeCommand::$passthroughVariables,
            'PHPRC', 'PHP_INI_SCAN_DIR', 'TEMP', 'TMP', 'TMPDIR',
        ]));
    }

    public function boot(): void
    {
        RateLimiter::for('api', fn (Request $request) => Limit::perMinute(120)->by($request->user()?->id ?: $request->ip()));

        // Sign-in, sign-up and reset emails: slow down password guessing.
        RateLimiter::for('auth', fn (Request $request) => [
            Limit::perMinute(10)->by($request->ip().'|'.strtolower((string) $request->input('email'))),
            Limit::perMinute(30)->by($request->ip()),
        ]);
    }
}
