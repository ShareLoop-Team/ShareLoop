<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Item;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(\Database\Seeders\AdminPlatformSeeder::class);
    }

    public function test_guest_is_forbidden_from_admin_api(): void
    {
        $response = $this->getJson('/api/admin/overview');
        $response->assertStatus(401);
    }

    public function test_non_admin_user_is_forbidden(): void
    {
        $user = User::factory()->create(['is_admin' => false]);
        $response = $this->actingAs($user)->getJson('/api/admin/overview');
        $response->assertStatus(403);
    }

    public function test_admin_can_access_dashboard_overview(): void
    {
        $admin = User::where('email', 'nimal@shareloop.test')->first() ?: User::factory()->create(['is_admin' => true]);

        $response = $this->actingAs($admin)->getJson('/api/admin/overview');
        $response->assertStatus(200)
            ->assertJsonStructure([
                'kpis' => [
                    'total_users',
                    'total_donations',
                    'completed_handovers',
                    'pending_requests',
                    'system_health',
                ],
                'trends',
                'districts',
                'categories',
            ]);
    }

    public function test_admin_can_manage_categories(): void
    {
        $admin = User::where('email', 'nimal@shareloop.test')->first() ?: User::factory()->create(['is_admin' => true]);

        $createResponse = $this->actingAs($admin)->postJson('/api/admin/categories', [
            'name' => 'Musical Instruments',
            'icon_name' => 'music',
            'sort_order' => 10,
        ]);
        $createResponse->assertStatus(201);
        $this->assertDatabaseHas('categories', ['name' => 'Musical Instruments']);
    }

    public function test_web_admin_dashboard_renders(): void
    {
        $response = $this->get('/admin');
        $response->assertStatus(200);
        $response->assertSee('ShareLoop');
        $response->assertSee('Dashboard Overview');
    }
}
