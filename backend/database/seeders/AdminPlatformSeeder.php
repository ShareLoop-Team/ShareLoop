<?php

namespace Database\Seeders;

use App\Models\AdminPermission;
use App\Models\AdminRole;
use App\Models\SystemSetting;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class AdminPlatformSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Permissions list
        $permissionsByGroup = [
            'Users' => [
                ['slug' => 'users.view', 'name' => 'View Users'],
                ['slug' => 'users.manage', 'name' => 'Manage Users (Edit, Verify, Reset Password)'],
                ['slug' => 'users.ban', 'name' => 'Suspend and Ban Users'],
                ['slug' => 'users.delete', 'name' => 'Delete Users'],
            ],
            'Items & Posts' => [
                ['slug' => 'items.view', 'name' => 'View Listings'],
                ['slug' => 'items.moderate', 'name' => 'Approve, Reject and Hide Listings'],
                ['slug' => 'items.delete', 'name' => 'Delete Listings'],
            ],
            'Requests' => [
                ['slug' => 'requests.view', 'name' => 'View Item Requests'],
                ['slug' => 'requests.moderate', 'name' => 'Approve, Reject and Escalate Requests'],
            ],
            'Moderation' => [
                ['slug' => 'moderation.view', 'name' => 'View Reported Queue'],
                ['slug' => 'moderation.action', 'name' => 'Resolve Reports & Run AI Scan'],
            ],
            'Categories' => [
                ['slug' => 'categories.manage', 'name' => 'Create, Edit and Delete Categories'],
            ],
            'Reviews & Ratings' => [
                ['slug' => 'reviews.manage', 'name' => 'Moderate Reviews and Ratings'],
            ],
            'Gamification' => [
                ['slug' => 'gamification.manage', 'name' => 'Award Badges and Adjust Points'],
            ],
            'Analytics' => [
                ['slug' => 'analytics.view', 'name' => 'View Analytics and Heatmaps'],
                ['slug' => 'analytics.export', 'name' => 'Export Reports (PDF, Excel, CSV)'],
            ],
            'Security' => [
                ['slug' => 'security.manage', 'name' => 'Manage Security, IP Blacklist and Sessions'],
            ],
            'Audit' => [
                ['slug' => 'audit.view', 'name' => 'View System Audit Logs'],
            ],
            'Settings' => [
                ['slug' => 'settings.manage', 'name' => 'Manage System Settings and Maintenance'],
            ],
            'Database' => [
                ['slug' => 'database.inspect', 'name' => 'Inspect Database Tables and Records'],
            ],
            'API Monitoring' => [
                ['slug' => 'api.monitor', 'name' => 'View API Health & Endpoint Stats'],
            ],
            'Notifications' => [
                ['slug' => 'notifications.send', 'name' => 'Broadcast In-App, Email & Push Notifications'],
            ],
            'Super Admin' => [
                ['slug' => 'roles.manage', 'name' => 'Manage Admin Roles and Permissions'],
            ],
        ];

        $permissionModels = [];
        foreach ($permissionsByGroup as $group => $perms) {
            foreach ($perms as $perm) {
                $permissionModels[$perm['slug']] = AdminPermission::updateOrCreate(
                    ['slug' => $perm['slug']],
                    ['name' => $perm['name'], 'group' => $group]
                );
            }
        }

        // 2. Roles
        $superAdminRole = AdminRole::updateOrCreate(
            ['slug' => 'super-admin'],
            [
                'name' => 'Super Administrator',
                'description' => 'Full control over all platform modules, settings, and administrators.',
                'is_system' => true,
            ]
        );
        $superAdminRole->permissions()->sync(array_values(array_map(fn ($p) => $p->id, $permissionModels)));

        $moderatorRole = AdminRole::updateOrCreate(
            ['slug' => 'moderator'],
            [
                'name' => 'Community Moderator',
                'description' => 'Handles user verification, content moderation, reports, and reviews.',
                'is_system' => true,
            ]
        );
        $moderatorSlugs = [
            'users.view', 'users.ban', 'items.view', 'items.moderate',
            'requests.view', 'requests.moderate', 'moderation.view', 'moderation.action',
            'reviews.manage', 'gamification.manage', 'analytics.view'
        ];
        $moderatorRole->permissions()->sync(
            array_values(array_map(fn ($slug) => $permissionModels[$slug]->id, $moderatorSlugs))
        );

        $supportRole = AdminRole::updateOrCreate(
            ['slug' => 'support-staff'],
            [
                'name' => 'Support Staff',
                'description' => 'Customer assistance, user inspection, requests inquiry, and notification broadcasts.',
                'is_system' => true,
            ]
        );
        $supportSlugs = ['users.view', 'users.manage', 'items.view', 'requests.view', 'audit.view', 'notifications.send'];
        $supportRole->permissions()->sync(
            array_values(array_map(fn ($slug) => $permissionModels[$slug]->id, $supportSlugs))
        );

        $contentReviewerRole = AdminRole::updateOrCreate(
            ['slug' => 'content-reviewer'],
            [
                'name' => 'Content Reviewer',
                'description' => 'Responsible for approving item listings, categories, and AI moderation review.',
                'is_system' => true,
            ]
        );
        $contentReviewerSlugs = ['items.view', 'items.moderate', 'requests.view', 'moderation.view', 'categories.manage'];
        $contentReviewerRole->permissions()->sync(
            array_values(array_map(fn ($slug) => $permissionModels[$slug]->id, $contentReviewerSlugs))
        );

        // 3. Assign super admin role to demo admin
        $admin = User::where('email', 'nimal@shareloop.test')->first();
        if ($admin) {
            $admin->update([
                'role_id' => $superAdminRole->id,
                'is_admin' => true,
                'is_verified' => true,
                'points' => 350,
                'badge' => 'Gold',
                'trust_score' => 98,
            ]);
        }

        // 4. Default System Settings
        $defaultSettings = [
            'app_name' => ['ShareLoop Sri Lanka', 'string', 'general', 'Platform public title'],
            'maintenance_mode' => [false, 'boolean', 'general', 'Temporarily disable public app access'],
            'contact_email' => ['support@shareloop.lk', 'string', 'email', 'Primary support and notification email'],
            'enable_ai_moderation' => [true, 'boolean', 'security', 'Automatically screen new listings for scam/toxic text'],
            'max_active_requests_per_user' => [5, 'integer', 'general', 'Limit concurrent pending item requests per user'],
            'enable_push_notifications' => [true, 'boolean', 'notifications', 'Enable FCM push alerts for handovers and messages'],
            'default_locale' => ['en', 'string', 'localization', 'Default fallback language (en, si, ta)'],
            'allow_guest_browsing' => [true, 'boolean', 'general', 'Allow unauthenticated users to view public give-away items'],
            'require_email_verification' => [false, 'boolean', 'security', 'Require verified email to request items'],
        ];

        foreach ($defaultSettings as $key => [$val, $type, $group, $desc]) {
            SystemSetting::updateOrCreate(
                ['key' => $key],
                ['value' => is_bool($val) ? ($val ? '1' : '0') : (string) $val, 'type' => $type, 'group' => $group, 'description' => $desc]
            );
        }
    }
}
