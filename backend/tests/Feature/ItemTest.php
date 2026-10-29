<?php

namespace Tests\Feature;

use App\Models\Item;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class ItemTest extends ShareLoopTestCase
{
    private function postData(array $overrides = []): array
    {
        return array_merge([
            'title' => 'School bag',
            'description' => 'Blue backpack',
            'condition' => 'Good',
            'category' => 'School Supplies',
            'district' => 'Kandy',
            'city' => 'Peradeniya',
        ], $overrides);
    }

    public function test_create_post_with_photos_stores_them_in_the_donors_folder(): void
    {
        Storage::fake('local');
        $donor = $this->makeUser(['display_name' => 'Nimal']);

        $response = $this->actingAsUser($donor)->post('/api/items', $this->postData([
            'photos' => [
                UploadedFile::fake()->image('bag.jpg', 400, 300),
                UploadedFile::fake()->image('bag2.png', 400, 300),
            ],
        ]), ['Accept' => 'application/json']);

        $response->assertCreated()
            ->assertJsonPath('data.donor_id', $donor->id)
            ->assertJsonPath('data.donor.display_name', 'Nimal')
            ->assertJsonPath('data.status', 'active')
            ->assertJsonCount(2, 'data.image_paths')
            ->assertJsonCount(2, 'data.image_urls');

        $paths = $response->json('data.image_paths');
        foreach ($paths as $path) {
            $this->assertStringStartsWith('item-images/'.$donor->id.'/', $path);
            Storage::disk('local')->assertExists($path);
        }

        // Signed URLs work without a token; tampered or unsigned ones don't.
        $url = $response->json('data.image_urls.0');
        $this->get($url)->assertOk();
        $this->getJson('/api/photos/'.$paths[0])->assertStatus(403);
    }

    public function test_photos_must_be_images_within_limits(): void
    {
        Storage::fake('local');
        $donor = $this->makeUser();

        $this->actingAsUser($donor)->post('/api/items', $this->postData([
            'photos' => [UploadedFile::fake()->create('virus.exe', 10, 'application/octet-stream')],
        ]), ['Accept' => 'application/json'])->assertStatus(422)->assertJsonValidationErrors('photos.0');

        $this->actingAsUser($donor)->post('/api/items', $this->postData([
            'photos' => [UploadedFile::fake()->image('huge.jpg')->size(6000)],
        ]), ['Accept' => 'application/json'])->assertStatus(422);

        $this->actingAsUser($donor)->post('/api/items', $this->postData([
            'photos' => array_fill(0, 6, UploadedFile::fake()->image('a.jpg')),
        ]), ['Accept' => 'application/json'])->assertStatus(422)->assertJsonValidationErrors('photos');

        $this->assertDatabaseCount('items', 0);
        $this->assertSame([], Storage::disk('local')->allFiles());
    }

    public function test_create_post_validates_fields(): void
    {
        $donor = $this->makeUser();

        $this->actingAsUser($donor)->postJson('/api/items', $this->postData([
            'condition' => 'Broken', 'category' => 'Weapons', 'district' => 'Paris', 'title' => '   ',
        ]))->assertStatus(422)->assertJsonValidationErrors(['condition', 'category', 'district', 'title']);
    }

    public function test_feed_is_newest_first_paged_and_hides_moderated_posts(): void
    {
        $donor = $this->makeUser();
        $viewer = $this->makeUser();
        $old = $this->makeItem($donor, ['title' => 'Old']);
        $old->forceFill(['created_at' => now()->subDay()])->save();
        $this->makeItem($donor, ['title' => 'New']);
        $this->makeItem($donor, ['title' => 'Hidden', 'is_hidden' => true]);

        $this->actingAsUser($viewer)->getJson('/api/items')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.title', 'New')
            ->assertJsonPath('data.1.title', 'Old');

        $this->actingAsUser($viewer)->getJson('/api/items?limit=1&offset=1')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Old');

        $this->actingAsUser($viewer)->getJson('/api/items?q=ol')->assertJsonCount(1, 'data');
        $this->actingAsUser($viewer)->getJson('/api/items?category=Clothes')->assertJsonCount(0, 'data');
    }

    public function test_hidden_posts_are_visible_only_to_their_donor_and_admins(): void
    {
        $donor = $this->makeUser();
        $other = $this->makeUser();
        $hidden = $this->makeItem($donor, ['is_hidden' => true]);

        $this->actingAsUser($other)->getJson('/api/items/'.$hidden->id)->assertNotFound();
        $this->actingAsUser($other)->getJson('/api/items?donor_id='.$donor->id)->assertJsonCount(0, 'data');
        $this->actingAsUser($donor)->getJson('/api/items/'.$hidden->id)->assertOk();
        $this->actingAsUser($donor)->getJson('/api/items?donor_id='.$donor->id)->assertJsonCount(1, 'data');
        $this->actingAsUser($this->makeAdmin())->getJson('/api/items/'.$hidden->id)->assertOk();
    }

    public function test_donor_deletes_post_with_its_photos_and_requests(): void
    {
        Storage::fake('local');
        $donor = $this->makeUser();
        $created = $this->actingAsUser($donor)->post('/api/items', $this->postData([
            'photos' => [UploadedFile::fake()->image('a.jpg')],
        ]), ['Accept' => 'application/json'])->json('data');
        $item = Item::find($created['id']);
        $this->makeRequest($this->makeUser(), $item);

        $this->actingAsUser($donor)->deleteJson('/api/items/'.$item->id)->assertOk();

        $this->assertDatabaseMissing('items', ['id' => $item->id]);
        $this->assertDatabaseCount('item_requests', 0);
        Storage::disk('local')->assertMissing($created['image_paths'][0]);
    }

    public function test_only_the_donor_or_an_admin_can_delete_and_not_during_handover(): void
    {
        $donor = $this->makeUser();
        $item = $this->makeItem($donor);

        $this->actingAsUser($this->makeUser())->deleteJson('/api/items/'.$item->id)->assertForbidden();

        $item->forceFill(['status' => Item::STATUS_PENDING_HANDOVER])->save();
        $this->actingAsUser($donor)->deleteJson('/api/items/'.$item->id)
            ->assertStatus(409)
            ->assertJsonPath('message', "This post can't be deleted while a handover is in progress.");

        $this->actingAsUser($this->makeAdmin())->deleteJson('/api/items/'.$item->id)->assertOk();
    }
}
