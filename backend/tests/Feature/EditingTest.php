<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\ItemRequest;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

/** Editing posts and requests, and profile photos. */
class EditingTest extends ShareLoopTestCase
{
    private function editData(array $overrides = []): array
    {
        return array_merge([
            'title' => 'Science textbook',
            'description' => 'Grade 10 science, like new',
            'condition' => 'New',
            'category' => 'Educational Books',
            'district' => 'Kandy',
            'city' => 'Peradeniya',
        ], $overrides);
    }

    public function test_donor_edits_post_keeping_some_photos_and_adding_new_ones(): void
    {
        Storage::fake('local');
        $donor = $this->makeUser();
        $created = $this->actingAsUser($donor)->post('/api/items', $this->editData([
            'title' => 'Old title',
            'photos' => [
                UploadedFile::fake()->image('a.jpg'),
                UploadedFile::fake()->image('b.jpg'),
            ],
        ]), ['Accept' => 'application/json'])->assertCreated();
        [$keep, $drop] = $created->json('data.image_paths');
        $id = $created->json('data.id');

        $response = $this->post("/api/items/$id", $this->editData([
            'keep_paths' => [$keep, 'item-images/someone-else/x.jpg'],
            'photos' => [UploadedFile::fake()->image('c.png')],
        ]), ['Accept' => 'application/json']);

        $response->assertOk()
            ->assertJsonPath('data.title', 'Science textbook')
            ->assertJsonPath('data.district', 'Kandy')
            ->assertJsonPath('data.image_paths.0', $keep)
            ->assertJsonCount(2, 'data.image_paths');
        Storage::disk('local')->assertExists($keep);
        Storage::disk('local')->assertMissing($drop);
        Storage::disk('local')->assertExists($response->json('data.image_paths.1'));
    }

    public function test_only_the_donor_edits_and_only_while_available(): void
    {
        $donor = $this->makeUser();
        $item = $this->makeItem($donor);

        $this->actingAsUser($this->makeUser())
            ->postJson("/api/items/{$item->id}", $this->editData())
            ->assertForbidden();

        $item->forceFill(['status' => Item::STATUS_PENDING_HANDOVER])->save();
        $this->actingAsUser($donor)
            ->postJson("/api/items/{$item->id}", $this->editData())
            ->assertStatus(409);
    }

    public function test_requester_edits_own_pending_request(): void
    {
        $requester = $this->makeUser();
        $request = $this->makeRequest($requester);

        $this->actingAsUser($requester)->patchJson("/api/requests/{$request->id}", [
            'item_name' => 'Scientific calculator',
            'description' => 'For A/L maths',
            'reason' => 'Mine broke',
            'notes' => '',
            'category' => 'School Supplies',
            'district' => 'Galle',
            'city' => '',
        ])->assertOk()
            ->assertJsonPath('data.item_name', 'Scientific calculator')
            ->assertJsonPath('data.district', 'Galle');

        $this->actingAsUser($this->makeUser())
            ->patchJson("/api/requests/{$request->id}", ['reason' => 'x'])
            ->assertForbidden();

        $request->forceFill(['status' => ItemRequest::STATUS_APPROVED])->save();
        $this->actingAsUser($requester)->patchJson("/api/requests/{$request->id}", [
            'item_name' => 'Calculator', 'description' => 'd', 'reason' => 'r',
            'category' => 'School Supplies', 'district' => 'Galle',
        ])->assertStatus(409);
    }

    public function test_profile_photo_replaces_the_old_one_and_shows_on_posts(): void
    {
        Storage::fake('local');
        $user = $this->makeUser();

        $first = $this->actingAsUser($user)->post('/api/me/avatar', [
            'photo' => UploadedFile::fake()->image('me.jpg'),
        ], ['Accept' => 'application/json'])->assertOk();
        $oldPath = $user->fresh()->avatar_path;
        $this->assertNotNull($first->json('data.avatar_url'));

        $this->post('/api/me/avatar', [
            'photo' => UploadedFile::fake()->image('me2.png'),
        ], ['Accept' => 'application/json'])->assertOk();
        Storage::disk('local')->assertMissing($oldPath);
        Storage::disk('local')->assertExists($user->fresh()->avatar_path);

        $item = $this->makeItem($user);
        $this->getJson("/api/items/{$item->id}")
            ->assertJsonPath('data.donor.rating_avg', 0)
            ->assertJson(fn ($json) => $json->whereType('data.donor.avatar_url', 'string')->etc());

        $this->postJson('/api/me/avatar', [])->assertStatus(422);
    }
}
