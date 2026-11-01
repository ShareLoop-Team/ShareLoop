<?php

use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json([
    'app' => 'ShareLoop API',
    'docs' => 'See backend/README.md. API routes live under /api.',
]));

// The Web-based ShareLoop Admin Operations Platform
Route::get('/admin/{any?}', function () {
    return view('admin.dashboard');
})->where('any', '.*')->name('admin.dashboard');

// The Flutter web build, when tool\build_web_app.bat has put it in public/app.
Route::get('/app', function () {
    $index = public_path('app/index.html');
    abort_unless(is_file($index), 404, 'Build the web app first: tool\\build_web_app.bat');

    return response()->file($index, ['Cache-Control' => 'no-cache']);
});
