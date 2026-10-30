<?php

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ItemController;
use App\Http\Controllers\Api\ItemRequestController;
use App\Http\Controllers\Api\PhotoController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

/*
| ShareLoop REST API (prefix /api). Every route except auth, categories,
| photos and health needs `Authorization: Bearer <token>` from login/register.
*/

Route::get('/health', fn () => ['status' => 'ok', 'app' => 'ShareLoop API']);

Route::prefix('auth')->middleware('throttle:auth')->group(function () {
    Route::post('/code', [AuthController::class, 'requestCode']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/login-with-code', [AuthController::class, 'loginWithCode']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/google', [AuthController::class, 'google']);
    Route::post('/facebook', [AuthController::class, 'facebook']);
});

Route::get('/categories', [CategoryController::class, 'index']);

// Photo URLs are signed and expire; no bearer token needed so <img> tags work.
Route::get('/photos/{path}', [PhotoController::class, 'show'])
    ->where('path', '.*')
    ->middleware('signed')
    ->name('photos.show');

Route::middleware(['auth:sanctum', 'active'])->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::patch('/me', [ProfileController::class, 'update']);
    Route::get('/me/exchanges', [ProfileController::class, 'exchanges']);
    Route::post('/me/avatar', [ProfileController::class, 'updateAvatar']);

    Route::get('/users', [UserController::class, 'index']);
    Route::get('/users/{id}', [UserController::class, 'show']);
    Route::get('/users/{id}/ratings', [UserController::class, 'ratings']);

    Route::get('/items', [ItemController::class, 'index']);
    Route::post('/items', [ItemController::class, 'store']);
    Route::get('/items/{id}', [ItemController::class, 'show']);
    // POST, not PATCH: PHP only parses multipart (photo) bodies on POST.
    Route::post('/items/{id}', [ItemController::class, 'update']);
    Route::delete('/items/{id}', [ItemController::class, 'destroy']);
    Route::get('/items/{id}/exchange', [ItemController::class, 'exchange']);
    Route::post('/items/{id}/confirm-handover', [ItemController::class, 'confirmHandover']);
    Route::post('/items/{id}/cancel-exchange', [ItemController::class, 'cancelExchange']);
    Route::post('/items/{id}/ratings', [ItemController::class, 'rate']);

    Route::get('/requests', [ItemRequestController::class, 'index']);
    Route::post('/requests', [ItemRequestController::class, 'store']);
    Route::patch('/requests/{id}', [ItemRequestController::class, 'update']);
    Route::delete('/requests/{id}', [ItemRequestController::class, 'destroy']);
    Route::post('/requests/{id}/select', [ItemRequestController::class, 'select']);

    Route::get('/reports', [ReportController::class, 'index']);
    Route::post('/reports', [ReportController::class, 'store']);

    Route::middleware('admin')->prefix('admin')->group(function () {
        Route::get('/users', [AdminController::class, 'users']);
        Route::patch('/users/{id}/status', [AdminController::class, 'setUserStatus']);
        Route::get('/items', [AdminController::class, 'items']);
        Route::patch('/items/{id}/hidden', [AdminController::class, 'setItemHidden']);
        Route::patch('/requests/{id}/hidden', [AdminController::class, 'setRequestHidden']);
        Route::patch('/reports/{id}', [AdminController::class, 'resolveReport']);
        Route::post('/categories', [CategoryController::class, 'store']);
        Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);
    });
});
