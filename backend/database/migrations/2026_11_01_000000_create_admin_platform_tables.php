<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Admin Roles & Permissions
        Schema::create('admin_roles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name', 60);
            $table->string('slug', 60)->unique();
            $table->string('description', 255)->nullable();
            $table->boolean('is_system')->default(false);
            $table->timestamps();
        });

        Schema::create('admin_permissions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name', 80);
            $table->string('slug', 80)->unique();
            $table->string('group', 60); // e.g. users, items, moderation, settings
            $table->timestamps();
        });

        Schema::create('admin_role_permission', function (Blueprint $table) {
            $table->foreignUuid('role_id')->constrained('admin_roles')->cascadeOnDelete();
            $table->foreignUuid('permission_id')->constrained('admin_permissions')->cascadeOnDelete();
            $table->primary(['role_id', 'permission_id']);
        });

        // Add admin role, ban tracking, gamification and verification fields to users
        Schema::table('users', function (Blueprint $table) {
            $table->foreignUuid('role_id')->nullable()->constrained('admin_roles')->nullOnDelete();
            $table->boolean('is_banned')->default(false);
            $table->timestamp('banned_at')->nullable();
            $table->string('ban_reason', 500)->nullable();
            $table->boolean('is_verified')->default(false);
            $table->integer('points')->default(0);
            $table->string('badge', 40)->default('Bronze'); // Bronze, Silver, Gold, Platinum
            $table->integer('trust_score')->default(100);
            $table->timestamp('last_login_at')->nullable();
            $table->string('last_login_ip', 45)->nullable();
        });

        // Add approval status to items
        Schema::table('items', function (Blueprint $table) {
            $table->string('moderation_status', 20)->default('approved'); // approved, pending, rejected, archived
            $table->text('moderation_notes')->nullable();
            $table->foreignUuid('moderated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('moderated_at')->nullable();
            $table->integer('ai_toxicity_score')->default(0); // 0-100
            $table->integer('ai_scam_score')->default(0); // 0-100
            $table->boolean('ai_flagged')->default(false);
        });

        // 2. Audit Logs
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action', 100); // e.g. user.suspended, item.approved, setting.updated
            $table->string('entity_type', 80)->nullable();
            $table->string('entity_id', 80)->nullable();
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();

            $table->index(['entity_type', 'entity_id']);
            $table->index(['action', 'created_at']);
        });

        // 3. Security Logs & Failed Logins
        Schema::create('security_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('event_type', 60); // failed_login, suspicious_access, ip_blocked, password_reset
            $table->string('severity', 20)->default('info'); // info, warning, critical
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->json('details')->nullable();
            $table->timestamps();

            $table->index(['event_type', 'severity']);
            $table->index(['ip_address', 'created_at']);
        });

        // 4. Blacklisted IPs
        Schema::create('blacklisted_ips', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('ip_address', 45)->unique();
            $table->string('reason', 255)->nullable();
            $table->foreignUuid('blocked_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('blocked_until')->nullable();
            $table->timestamps();
        });

        // 5. System Settings
        Schema::create('system_settings', function (Blueprint $table) {
            $table->string('key', 80)->primary();
            $table->longText('value')->nullable();
            $table->string('type', 20)->default('string'); // string, json, boolean, integer
            $table->string('group', 40)->default('general'); // general, email, notifications, security, localization
            $table->string('description', 255)->nullable();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        // 6. Admin Notifications (Broadcasts & Announcements)
        Schema::create('admin_notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title', 160);
            $table->text('message');
            $table->string('target_type', 30)->default('all'); // all, donors, requesters, specific
            $table->json('target_user_ids')->nullable();
            $table->string('channel', 30)->default('in_app'); // in_app, email, push, all
            $table->foreignUuid('sent_by')->nullable()->constrained('users')->nullOnDelete();
            $table->integer('recipients_count')->default(0);
            $table->timestamps();
        });

        // 7. API Metrics & Monitoring Logs
        Schema::create('api_metrics', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('method', 10);
            $table->string('endpoint', 200);
            $table->integer('status_code');
            $table->float('response_time_ms');
            $table->string('ip_address', 45)->nullable();
            $table->timestamps();

            $table->index(['endpoint', 'created_at']);
            $table->index(['status_code', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('api_metrics');
        Schema::dropIfExists('admin_notifications');
        Schema::dropIfExists('system_settings');
        Schema::dropIfExists('blacklisted_ips');
        Schema::dropIfExists('security_logs');
        Schema::dropIfExists('audit_logs');

        Schema::table('items', function (Blueprint $table) {
            $table->dropForeign(['moderated_by']);
            $table->dropColumn([
                'moderation_status', 'moderation_notes', 'moderated_by',
                'moderated_at', 'ai_toxicity_score', 'ai_scam_score', 'ai_flagged'
            ]);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['role_id']);
            $table->dropColumn([
                'role_id', 'is_banned', 'banned_at', 'ban_reason', 'is_verified',
                'points', 'badge', 'trust_score', 'last_login_at', 'last_login_ip'
            ]);
        });

        Schema::dropIfExists('admin_role_permission');
        Schema::dropIfExists('admin_permissions');
        Schema::dropIfExists('admin_roles');
    }
};
