<?php

namespace Tests\Feature;

use App\Models\User;

class AdminTest extends ShareLoopTestCase
{
    public function test_admin_routes_are_admin_only(): void
    {
        $user = $this->makeUser();
        foreach (['/api/admin/users', '/api/admin/items'] as $url) {
            $this->actingAsUser($user)->getJson($url)->assertForbidden();
        }
        $this->actingAsUser($user)->postJson('/api/admin/categories', ['name' => 'Toys'])->assertForbidden();
    }

    public function test_suspending_a_user_cuts_access_immediately(): void
    {
        $admin = $this->makeAdmin();
        $user = $this->makeUser();
        $user->createToken('phone');

        $this->actingAsUser($admin)->getJson('/api/admin/users')->assertJsonCount(2, 'data');
        $this->actingAsUser($admin)
            ->patchJson('/api/admin/users/'.$user->id.'/status', ['status' => 'suspended'])
            ->assertOk()->assertJsonPath('data.status', 'suspended');

        $this->assertSame(User::STATUS_SUSPENDED, $user->fresh()->status);
        $this->assertSame(0, $user->tokens()->count());
        $this->actingAsUser($admin)->getJson('/api/admin/users')->assertJsonCount(1, 'data');
        $this->actingAsUser($admin)->getJson('/api/admin/users?status=suspended')->assertJsonCount(1, 'data');

        $this->actingAsUser($admin)
            ->patchJson('/api/admin/users/'.$admin->id.'/status', ['status' => 'suspended'])
            ->assertStatus(422);
    }

    public function test_hiding_a_post_removes_it_from_the_feed_but_not_for_its_donor(): void
    {
        $admin = $this->makeAdmin();
        $donor = $this->makeUser();
        $item = $this->makeItem($donor);

        $this->actingAsUser($admin)->getJson('/api/admin/items')->assertJsonCount(1, 'data');
        $this->actingAsUser($admin)
            ->patchJson('/api/admin/items/'.$item->id.'/hidden', ['hidden' => true, 'reason' => 'Spam'])
            ->assertOk()->assertJsonPath('data.is_hidden', true);

        $this->actingAsUser($this->makeUser())->getJson('/api/items')->assertJsonCount(0, 'data');
        $this->actingAsUser($donor)->getJson('/api/items/'.$item->id)->assertOk();
        $this->actingAsUser($admin)->getJson('/api/admin/items')->assertJsonCount(0, 'data');
        $this->actingAsUser($admin)->getJson('/api/admin/items?hidden=1')->assertJsonCount(1, 'data');
    }

    public function test_hiding_a_need_removes_it_from_the_requests_feed(): void
    {
        $admin = $this->makeAdmin();
        $need = $this->makeRequest($this->makeUser());

        $this->actingAsUser($admin)
            ->patchJson('/api/admin/requests/'.$need->id.'/hidden', ['hidden' => true])->assertOk();
        $this->actingAsUser($this->makeUser())->getJson('/api/requests')->assertJsonCount(0, 'data');
    }

    public function test_categories_can_be_added_and_retired(): void
    {
        $admin = $this->makeAdmin();
        $user = $this->makeUser();

        $this->getJson('/api/categories')->assertOk()->assertJsonCount(7, 'data')
            ->assertJsonPath('data.0.name', 'Educational Books');

        $id = $this->actingAsUser($admin)
            ->postJson('/api/admin/categories', ['name' => 'Toys', 'icon_name' => 'toys'])
            ->assertCreated()->json('data.id');
        $this->actingAsUser($admin)->postJson('/api/admin/categories', ['name' => 'Toys'])->assertStatus(409);
        $this->getJson('/api/categories')->assertJsonCount(8, 'data');

        $this->actingAsUser($user)->postJson('/api/items', [
            'title' => 'Lego', 'description' => 'Box of lego', 'condition' => 'Good',
            'category' => 'Toys', 'district' => 'Colombo',
        ])->assertCreated();

        $this->actingAsUser($admin)->deleteJson('/api/admin/categories/'.$id)->assertOk();
        $this->getJson('/api/categories')->assertJsonCount(7, 'data');
        $this->actingAsUser($user)->postJson('/api/items', [
            'title' => 'More lego', 'description' => 'Another box', 'condition' => 'Good',
            'category' => 'Toys', 'district' => 'Colombo',
        ])->assertStatus(422);
        // Existing posts keep their category.
        $this->actingAsUser($user)->getJson('/api/items')->assertJsonPath('data.0.category', 'Toys');
    }

    public function test_reports_are_filed_once_and_resolved_by_admins(): void
    {
        $admin = $this->makeAdmin();
        $reporter = $this->makeUser();
        $item = $this->makeItem($this->makeUser());

        $id = $this->actingAsUser($reporter)
            ->postJson('/api/reports', ['item_id' => $item->id, 'reason' => 'spam'])
            ->assertCreated()->json('data.id');
        $this->actingAsUser($reporter)
            ->postJson('/api/reports', ['item_id' => $item->id, 'reason' => 'scam'])
            ->assertStatus(409);
        $this->actingAsUser($reporter)
            ->postJson('/api/reports', ['item_id' => $item->id, 'reported_user_id' => $admin->id, 'reason' => 'spam'])
            ->assertStatus(422);

        $this->actingAsUser($this->makeUser())->getJson('/api/reports')->assertJsonCount(0, 'data');
        $this->actingAsUser($admin)->getJson('/api/reports?status=open')->assertJsonCount(1, 'data');
        $this->actingAsUser($reporter)->patchJson('/api/admin/reports/'.$id, ['status' => 'dismissed'])->assertForbidden();
        $this->actingAsUser($admin)
            ->patchJson('/api/admin/reports/'.$id, ['status' => 'actioned', 'note' => 'Hidden'])
            ->assertOk()->assertJsonPath('data.status', 'actioned')
            ->assertJsonPath('data.resolved_by', $admin->id);
    }
}
