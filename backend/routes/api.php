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
        // Module 1: Dashboard Overview
        Route::get('/overview', [\App\Http\Controllers\Api\Admin\AdminDashboardController::class, 'overview']);

        // Module 2: User Management
        Route::get('/users', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'index']);
        Route::get('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'show']);
        Route::patch('/users/{id}/status', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'updateStatus']);
        Route::post('/users/{id}/reset-password', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'resetPassword']);
        Route::post('/users/{id}/force-logout', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'forceLogout']);
        Route::delete('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'destroy']);

        // Module 3: Item Management
        Route::get('/items', [\App\Http\Controllers\Api\Admin\AdminItemController::class, 'index']);
        Route::get('/items/{id}', [\App\Http\Controllers\Api\Admin\AdminItemController::class, 'show']);
        Route::patch('/items/{id}/moderation', [\App\Http\Controllers\Api\Admin\AdminItemController::class, 'updateModeration']);
        Route::post('/items/{id}/ai-scan', [\App\Http\Controllers\Api\Admin\AdminItemController::class, 'runAiScan']);
        Route::delete('/items/{id}', [\App\Http\Controllers\Api\Admin\AdminItemController::class, 'destroy']);
        Route::patch('/items/{id}/hidden', [AdminController::class, 'setItemHidden']);

        // Module 4: Request Management
        Route::get('/requests', [\App\Http\Controllers\Api\Admin\AdminRequestController::class, 'index']);
        Route::get('/requests/{id}', [\App\Http\Controllers\Api\Admin\AdminRequestController::class, 'show']);
        Route::patch('/requests/{id}/status', [\App\Http\Controllers\Api\Admin\AdminRequestController::class, 'updateStatus']);
        Route::patch('/requests/{id}/hidden', [AdminController::class, 'setRequestHidden']);

        // Module 5: Moderation Center
        Route::get('/moderation/reports', [\App\Http\Controllers\Api\Admin\AdminModerationController::class, 'index']);
        Route::patch('/moderation/reports/{id}', [\App\Http\Controllers\Api\Admin\AdminModerationController::class, 'resolve']);
        Route::patch('/reports/{id}', [AdminController::class, 'resolveReport']);

        // Module 6: Category Management
        Route::get('/categories', [\App\Http\Controllers\Api\Admin\AdminCategoryController::class, 'index']);
        Route::post('/categories', [\App\Http\Controllers\Api\Admin\AdminCategoryController::class, 'store']);
        Route::put('/categories/{id}', [\App\Http\Controllers\Api\Admin\AdminCategoryController::class, 'update']);
        Route::delete('/categories/{id}', [\App\Http\Controllers\Api\Admin\AdminCategoryController::class, 'destroy']);

        // Module 7: Reviews & Ratings
        Route::get('/reviews', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'index']);
        Route::delete('/reviews/{id}', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'destroy']);

        // Module 8: Gamification System
        Route::get('/gamification', [\App\Http\Controllers\Api\Admin\AdminGamificationController::class, 'index']);
        Route::patch('/gamification/{id}', [\App\Http\Controllers\Api\Admin\AdminGamificationController::class, 'update']);

        // Module 9: Location Management
        Route::get('/locations', [\App\Http\Controllers\Api\Admin\AdminLocationController::class, 'index']);

        // Module 10: Analytics & Reports
        Route::get('/analytics', [\App\Http\Controllers\Api\Admin\AdminAnalyticsController::class, 'index']);
        Route::get('/analytics/export/{type}', [\App\Http\Controllers\Api\Admin\AdminAnalyticsController::class, 'export']);

        // Module 11: Security Center
        Route::get('/security', [\App\Http\Controllers\Api\Admin\AdminSecurityController::class, 'index']);
        Route::post('/security/blacklist', [\App\Http\Controllers\Api\Admin\AdminSecurityController::class, 'addBlacklistedIp']);
        Route::delete('/security/blacklist/{id}', [\App\Http\Controllers\Api\Admin\AdminSecurityController::class, 'removeBlacklistedIp']);
        Route::post('/security/users/{id}/revoke-sessions', [\App\Http\Controllers\Api\Admin\AdminSecurityController::class, 'revokeUserSessions']);

        // Module 12: Audit Logs
        Route::get('/audit-logs', [\App\Http\Controllers\Api\Admin\AdminAuditController::class, 'index']);
        Route::get('/audit-logs/{id}', [\App\Http\Controllers\Api\Admin\AdminAuditController::class, 'show']);

        // Module 13: System Settings
        Route::get('/settings', [\App\Http\Controllers\Api\Admin\AdminSettingsController::class, 'index']);
        Route::post('/settings', [\App\Http\Controllers\Api\Admin\AdminSettingsController::class, 'update']);
        Route::post('/settings/toggle-maintenance', [\App\Http\Controllers\Api\Admin\AdminSettingsController::class, 'toggleMaintenance']);

        // Module 14: Database Inspector
        Route::get('/database/tables', [\App\Http\Controllers\Api\Admin\AdminDatabaseController::class, 'tables']);
        Route::get('/database/tables/{table}', [\App\Http\Controllers\Api\Admin\AdminDatabaseController::class, 'queryTable']);

        // Module 15: API Monitoring
        Route::get('/monitoring', [\App\Http\Controllers\Api\Admin\AdminMonitoringController::class, 'index']);

        // Module 16: Notification Center
        Route::get('/notifications', [\App\Http\Controllers\Api\Admin\AdminNotificationController::class, 'index']);
        Route::post('/notifications/broadcast', [\App\Http\Controllers\Api\Admin\AdminNotificationController::class, 'broadcast']);

        // Module 17: Super Admin Panel
        Route::get('/roles', [\App\Http\Controllers\Api\Admin\AdminRoleController::class, 'index']);
        Route::post('/roles/assign/{userId}', [\App\Http\Controllers\Api\Admin\AdminRoleController::class, 'assignRole']);
        Route::put('/roles/{roleId}/permissions', [\App\Http\Controllers\Api\Admin\AdminRoleController::class, 'updateRolePermissions']);
    });
});
