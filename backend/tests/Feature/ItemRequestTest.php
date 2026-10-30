<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\ItemRequest;

class ItemRequestTest extends ShareLoopTestCase
{
    private function need(array $overrides = []): array
    {
        return array_merge([
            'item_name' => 'Calculator',
            'description' => 'Scientific calculator',
            'reason' => 'A/L maths',
            'notes' => '',
            'category' => 'School Supplies',
            'district' => 'Galle',
            'city' => 'Hikkaduwa',
        ], $overrides);
    }

    public function test_standalone_needs_are_visible_to_every_signed_in_user(): void
    {
        $requester = $this->makeUser(['display_name' => 'Kavya']);

        $this->actingAsUser($requester)->postJson('/api/requests', $this->need())
            ->assertCreated()
            ->assertJsonPath('data.item_id', null)
            ->assertJsonPath('data.requester.display_name', 'Kavya')
            ->assertJsonPath('data.status', 'pending');

        $this->actingAsUser($this->makeUser())->getJson('/api/requests')->assertJsonCount(1, 'data');
    }

    public function test_a_need_must_name_the_item(): void
    {
        $this->actingAsUser($this->makeUser())
            ->postJson('/api/requests', $this->need(['item_name' => '']))
            ->assertStatus(422)->assertJsonValidationErrors('item_name');
    }

    public function test_requests_for_an_item_are_private_to_requester_and_donor(): void
    {
        $donor = $this->makeUser();
        $requester = $this->makeUser();
        $outsider = $this->makeUser();
        $item = $this->makeItem($donor);

        $this->actingAsUser($requester)->postJson('/api/requests', $this->need([
            'item_id' => $item->id, 'item_name' => '',
        ]))->assertCreated();

        $this->actingAsUser($donor)->getJson('/api/requests?item_id='.$item->id)->assertJsonCount(1, 'data');
        $this->actingAsUser($requester)->getJson('/api/requests?requester_id='.$requester->id)->assertJsonCount(1, 'data');
        $this->actingAsUser($outsider)->getJson('/api/requests?item_id='.$item->id)->assertJsonCount(0, 'data');
        $this->actingAsUser($outsider)->getJson('/api/requests')->assertJsonCount(0, 'data');
    }

    public function test_item_request_rules(): void
    {
        $donor = $this->makeUser();
        $requester = $this->makeUser();
        $item = $this->makeItem($donor);
        $body = $this->need(['item_id' => $item->id, 'item_name' => '']);

        $this->actingAsUser($donor)->postJson('/api/requests', $body)
            ->assertStatus(422)->assertJsonPath('message', 'You cannot request your own item.');

        $this->actingAsUser($requester)->postJson('/api/requests', $body)->assertCreated();
        $this->actingAsUser($requester)->postJson('/api/requests', $body)
            ->assertStatus(409)->assertJsonPath('message', 'You have already requested this item.');

        $taken = $this->makeItem($donor, ['status' => Item::STATUS_PENDING_HANDOVER]);
        $this->actingAsUser($requester)->postJson('/api/requests', $this->need(['item_id' => $taken->id]))
            ->assertStatus(409)->assertJsonPath('message', 'This item is no longer available.');

        $hidden = $this->makeItem($donor, ['is_hidden' => true]);
        $this->actingAsUser($requester)->postJson('/api/requests', $this->need(['item_id' => $hidden->id]))
            ->assertNotFound();
    }

    public function test_requesters_delete_their_own_requests_unless_approved(): void
    {
        $requester = $this->makeUser();
        $mine = $this->makeRequest($requester);
        $approved = $this->makeRequest($requester, $this->makeItem($this->makeUser()));
        $approved->forceFill(['status' => ItemRequest::STATUS_APPROVED])->save();

        $this->actingAsUser($this->makeUser())->deleteJson('/api/requests/'.$mine->id)->assertForbidden();
        $this->actingAsUser($requester)->deleteJson('/api/requests/'.$approved->id)
            ->assertStatus(409)->assertJsonPath('message', "An approved request can't be deleted.");
        $this->actingAsUser($requester)->deleteJson('/api/requests/'.$mine->id)->assertOk();
        $this->assertDatabaseMissing('item_requests', ['id' => $mine->id]);
    }
}
