<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\ItemRequest;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

abstract class ShareLoopTestCase extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    protected function makeUser(array $attributes = []): User
    {
        $user = User::create(array_merge([
            'display_name' => 'User '.Str::random(4),
            'email' => Str::lower(Str::random(8)).'@example.com',
            'password' => 'secret123',
            'phone' => '0771234567',
            'district' => 'Colombo',
            'city' => 'Colombo',
        ], array_intersect_key($attributes, array_flip(['display_name', 'email', 'password', 'phone', 'district', 'city']))));
        $extra = array_intersect_key($attributes, array_flip(['is_admin', 'status', 'donation_count']));
        if ($extra !== []) {
            $user->forceFill($extra)->save();
        }

        return $user->fresh();
    }

    protected function makeAdmin(): User
    {
        return $this->makeUser(['is_admin' => true]);
    }

    protected function actingAsUser(User $user): static
    {
        Sanctum::actingAs($user);

        return $this;
    }

    protected function makeItem(User $donor, array $attributes = []): Item
    {
        $item = Item::create(array_merge([
            'donor_id' => $donor->id,
            'title' => 'Maths textbook',
            'description' => 'Grade 9 maths textbook',
            'condition' => 'Good',
            'category' => 'Educational Books',
            'district' => 'Colombo',
            'city' => 'Nugegoda',
            'image_paths' => [],
        ], array_diff_key($attributes, ['is_hidden' => 1, 'status' => 1])));
        $state = array_intersect_key($attributes, ['is_hidden' => 1, 'status' => 1]);
        if ($state !== []) {
            $item->forceFill($state)->save();
        }

        return $item->fresh();
    }

    protected function makeRequest(User $requester, ?Item $item = null, array $attributes = []): ItemRequest
    {
        return ItemRequest::create(array_merge([
            'requester_id' => $requester->id,
            'item_id' => $item?->id,
            'item_name' => $item ? '' : 'Calculator',
            'description' => 'I need this',
            'reason' => 'For school',
            'category' => 'Educational Books',
            'district' => 'Colombo',
            'city' => '',
        ], $attributes))->fresh();
    }
}
