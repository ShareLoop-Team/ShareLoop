<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Reference data, plus an admin account when SHARELOOP_ADMIN_EMAIL and
 * SHARELOOP_ADMIN_PASSWORD are set in .env. Demo content: DemoSeeder.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        foreach (config('shareloop.categories') as [$id, $name, $icon, $order]) {
            Category::query()->updateOrCreate(
                ['id' => $id],
                ['name' => $name, 'icon_name' => $icon, 'sort_order' => $order],
            );
        }

        $email = env('SHARELOOP_ADMIN_EMAIL');
        $password = env('SHARELOOP_ADMIN_PASSWORD');
        if ($email && $password) {
            $admin = User::query()->firstOrNew(['email' => strtolower($email)]);
            if (! $admin->exists) {
                $admin->fill([
                    'display_name' => 'ShareLoop Admin',
                    'password' => $password,
                    'phone' => '0770000000',
                    'district' => 'Colombo',
                    'city' => 'Colombo',
                ]);
            }
            $admin->forceFill(['is_admin' => true, 'status' => User::STATUS_ACTIVE])->save();
        }
    }
}
