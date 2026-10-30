<?php

namespace Tests\Feature;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class ApiBasicsTest extends ShareLoopTestCase
{
    public function test_health_and_unknown_routes_answer_in_json(): void
    {
        $this->getJson('/api/health')->assertOk()->assertJsonPath('status', 'ok');
        $this->getJson('/api/nope')->assertNotFound()->assertJsonStructure(['message']);
    }

    public function test_admins_see_contacts_ordinary_users_do_not(): void
    {
        $user = $this->makeUser(['phone' => '0779999999']);
        $other = $this->makeUser();

        $this->actingAsUser($other)->getJson('/api/users')->assertOk()
            ->assertJsonFragment(['id' => $user->id, 'phone' => null]);
        $this->actingAsUser($this->makeAdmin())->getJson('/api/users/'.$user->id)
            ->assertJsonPath('data.phone', '0779999999');
        $this->actingAsUser($user)->getJson('/api/auth/me')
            ->assertJsonPath('data.phone', '0779999999');
    }

    public function test_photo_links_expire(): void
    {
        Storage::fake('local');
        $donor = $this->makeUser();
        $url = $this->actingAsUser($donor)->post('/api/items', [
            'title' => 'Fan', 'description' => 'Table fan', 'condition' => 'Used',
            'category' => 'Household Items', 'district' => 'Galle',
            'photos' => [UploadedFile::fake()->image('fan.webp')],
        ], ['Accept' => 'application/json'])->assertCreated()->json('data.image_urls.0');

        $this->get($url)->assertOk();
        $this->travel(61)->minutes();
        $this->getJson($url)->assertForbidden()->assertJsonPath('message', 'This photo link has expired.');
    }

    public function test_cors_allows_the_flutter_web_app(): void
    {
        $this->withHeaders(['Origin' => 'http://localhost:5000'])
            ->getJson('/api/categories')
            ->assertOk()
            ->assertHeader('Access-Control-Allow-Origin', '*');
    }

    public function test_missing_records_are_404_with_a_message(): void
    {
        $user = $this->makeUser();
        $this->actingAsUser($user)->getJson('/api/users/does-not-exist')
            ->assertNotFound()->assertJsonPath('message', 'Not found.');
        $this->actingAsUser($user)->getJson('/api/items/does-not-exist')
            ->assertNotFound()->assertJsonPath('message', 'Item not found.');
    }
}
