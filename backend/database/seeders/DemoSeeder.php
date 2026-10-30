<?php

namespace Database\Seeders;

use App\Models\Item;
use App\Models\ItemRequest;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Sample accounts and posts for local development:
 *   php artisan db:seed --class=DemoSeeder
 * Every demo account uses the password "password".
 */
class DemoSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(DatabaseSeeder::class);

        $people = [
            ['Nimal Perera', 'nimal@shareloop.test', '0771234567', 'Colombo', 'Dehiwala', true],
            ['Kavya Fernando', 'kavya@shareloop.test', '0712345678', 'Kandy', 'Peradeniya', false],
            ['Ishara Silva', 'ishara@shareloop.test', '0759876543', 'Galle', 'Hikkaduwa', false],
        ];
        $users = [];
        foreach ($people as [$name, $email, $phone, $district, $city, $isAdmin]) {
            $user = User::query()->firstOrNew(['email' => $email]);
            if (! $user->exists) {
                $user->fill([
                    'display_name' => $name, 'password' => 'password', 'phone' => $phone,
                    'district' => $district, 'city' => $city,
                ]);
            }
            $user->forceFill(['is_admin' => $isAdmin])->save();
            $users[] = $user;
        }
        [$nimal, $kavya, $ishara] = $users;

        if (Item::query()->exists()) {
            return;
        }

        $items = [
            [$nimal, 'Grade 10 Science textbooks', 'Full set of Grade 10 science books, a few notes in pencil.', 'Good', 'Educational Books'],
            [$nimal, 'School bag', 'Blue backpack, barely used. Fits A4 books.', 'New', 'School Supplies'],
            [$kavya, 'Kids raincoats (2)', 'Two raincoats for ages 6-8.', 'Used', 'Clothes'],
            [$ishara, 'Table fan', 'Working 16 inch table fan.', 'Good', 'Household Items'],
        ];
        foreach ($items as [$donor, $title, $description, $condition, $category]) {
            Item::create([
                'donor_id' => $donor->id, 'title' => $title, 'description' => $description,
                'condition' => $condition, 'category' => $category,
                'district' => $donor->district, 'city' => $donor->city, 'image_paths' => [],
            ]);
        }

        ItemRequest::create([
            'requester_id' => $kavya->id,
            'item_name' => 'Scientific calculator',
            'description' => 'Casio fx-82 or similar for A/L maths.',
            'reason' => 'My daughter starts A/Ls next month.',
            'category' => 'School Supplies',
            'district' => $kavya->district,
            'city' => $kavya->city,
        ]);
        ItemRequest::create([
            'requester_id' => $ishara->id,
            'item_name' => 'Children\'s shoes, size 3',
            'description' => 'School shoes in black, size 3.',
            'reason' => 'Growing faster than we can buy them.',
            'category' => 'Shoes',
            'district' => $ishara->district,
            'city' => $ishara->city,
        ]);
    }
}
