<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\ItemRequest;
use App\Models\User;

class ExchangeTest extends ShareLoopTestCase
{
    private User $donor;
    private User $requester;
    private User $otherRequester;
    private Item $item;
    private ItemRequest $request;
    private ItemRequest $otherRequest;

    protected function setUp(): void
    {
        parent::setUp();
        $this->donor = $this->makeUser(['phone' => '0711111111', 'email' => 'donor@example.com']);
        $this->requester = $this->makeUser(['phone' => '0722222222', 'email' => 'req@example.com']);
        $this->otherRequester = $this->makeUser();
        $this->item = $this->makeItem($this->donor);
        $this->request = $this->makeRequest($this->requester, $this->item);
        $this->otherRequest = $this->makeRequest($this->otherRequester, $this->item);
    }

    private function select(): void
    {
        $this->actingAsUser($this->donor)
            ->postJson('/api/requests/'.$this->request->id.'/select')
            ->assertCreated();
    }

    public function test_full_handover_flow(): void
    {
        // Before selection, contact details are private.
        $this->actingAsUser($this->requester)->getJson('/api/users/'.$this->donor->id)
            ->assertJsonPath('data.phone', null)
            ->assertJsonPath('data.email', null);

        $this->actingAsUser($this->donor)
            ->postJson('/api/requests/'.$this->request->id.'/select')
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.donor_id', $this->donor->id)
            ->assertJsonPath('data.requester_id', $this->requester->id);

        $this->assertSame(Item::STATUS_PENDING_HANDOVER, $this->item->fresh()->status);
        $this->assertSame(ItemRequest::STATUS_APPROVED, $this->request->fresh()->status);
        $this->actingAsUser($this->otherRequester)->getJson('/api/items/'.$this->item->id)
            ->assertJsonPath('data.selected_requester_id', $this->requester->id);

        // Now the two parties see each other's contacts; others still don't.
        $this->actingAsUser($this->requester)->getJson('/api/users/'.$this->donor->id)
            ->assertJsonPath('data.phone', '0711111111');
        $this->actingAsUser($this->donor)->getJson('/api/users/'.$this->requester->id)
            ->assertJsonPath('data.email', 'req@example.com');
        $this->actingAsUser($this->otherRequester)->getJson('/api/users/'.$this->donor->id)
            ->assertJsonPath('data.phone', null);

        // Both confirm; the exchange completes only after the second.
        $this->actingAsUser($this->donor)->postJson('/api/items/'.$this->item->id.'/confirm-handover')
            ->assertOk()->assertJsonPath('data.status', 'pending');
        $this->actingAsUser($this->donor)->postJson('/api/items/'.$this->item->id.'/confirm-handover')
            ->assertOk()->assertJsonPath('data.status', 'pending');
        $this->actingAsUser($this->requester)->postJson('/api/items/'.$this->item->id.'/confirm-handover')
            ->assertOk()->assertJsonPath('data.status', 'completed');

        $this->assertSame(Item::STATUS_COMPLETED, $this->item->fresh()->status);
        $this->assertSame(1, $this->donor->fresh()->donation_count);
        $this->assertSame(ItemRequest::STATUS_REJECTED, $this->otherRequest->fresh()->status);

        $this->actingAsUser($this->requester)->getJson('/api/items/'.$this->item->id.'/exchange')
            ->assertJsonPath('data.status', 'completed');
    }

    public function test_only_the_donor_selects_and_only_once(): void
    {
        $this->actingAsUser($this->requester)
            ->postJson('/api/requests/'.$this->request->id.'/select')
            ->assertForbidden()->assertJsonPath('message', 'Only the donor can select a requester.');

        $this->select();

        $this->actingAsUser($this->donor)
            ->postJson('/api/requests/'.$this->otherRequest->id.'/select')
            ->assertStatus(409)->assertJsonPath('message', 'This item is no longer available.');
        $this->actingAsUser($this->otherRequester)->postJson('/api/requests', [
            'item_id' => $this->item->id, 'description' => 'x', 'reason' => 'y',
            'category' => 'Educational Books', 'district' => 'Colombo',
        ])->assertStatus(409);
    }

    public function test_outsiders_cannot_confirm_cancel_or_see_the_exchange(): void
    {
        $this->select();
        $url = '/api/items/'.$this->item->id;

        $this->actingAsUser($this->otherRequester)->postJson($url.'/confirm-handover')->assertForbidden();
        $this->actingAsUser($this->otherRequester)->postJson($url.'/cancel-exchange')->assertForbidden();
        $this->actingAsUser($this->otherRequester)->getJson($url.'/exchange')->assertExactJson(['data' => null]);
    }

    public function test_confirm_without_a_handover_is_not_found(): void
    {
        $this->actingAsUser($this->donor)
            ->postJson('/api/items/'.$this->item->id.'/confirm-handover')
            ->assertNotFound()->assertJsonPath('message', 'No handover in progress for this item.');
    }

    public function test_cancel_puts_the_item_back_on_offer_and_removes_ratings(): void
    {
        $this->select();
        $this->actingAsUser($this->donor)->postJson('/api/items/'.$this->item->id.'/confirm-handover');
        $this->actingAsUser($this->donor)
            ->postJson('/api/items/'.$this->item->id.'/ratings', ['stars' => 5])->assertCreated();
        $this->assertSame(1, $this->requester->fresh()->rating_count);

        $this->actingAsUser($this->requester)
            ->postJson('/api/items/'.$this->item->id.'/cancel-exchange')
            ->assertOk()->assertJsonPath('data.status', 'cancelled');

        $item = $this->item->fresh();
        $this->assertSame(Item::STATUS_ACTIVE, $item->status);
        $this->assertNull($item->selected_request_id);
        $this->assertSame(ItemRequest::STATUS_REJECTED, $this->request->fresh()->status);
        $this->assertSame(ItemRequest::STATUS_PENDING, $this->otherRequest->fresh()->status);
        $this->assertDatabaseCount('ratings', 0);
        $this->assertSame(0, $this->requester->fresh()->rating_count);
        $this->actingAsUser($this->donor)->getJson('/api/items/'.$this->item->id.'/exchange')
            ->assertExactJson(['data' => null]);

        // The donor can pick someone else now.
        $this->actingAsUser($this->donor)
            ->postJson('/api/requests/'.$this->otherRequest->id.'/select')->assertCreated();
    }

    public function test_ratings_need_a_confirmation_and_go_to_the_other_party(): void
    {
        $this->select();
        $url = '/api/items/'.$this->item->id.'/ratings';

        $this->actingAsUser($this->requester)->postJson($url, ['stars' => 4])
            ->assertForbidden()->assertJsonPath('message', 'Confirm the handover before rating.');

        $this->actingAsUser($this->requester)->postJson('/api/items/'.$this->item->id.'/confirm-handover');
        $this->actingAsUser($this->requester)
            ->postJson($url, ['stars' => 4, 'comment' => ' Lovely ', 'ratee_id' => $this->otherRequester->id])
            ->assertCreated()
            ->assertJsonPath('data.ratee_id', $this->donor->id)
            ->assertJsonPath('data.comment', 'Lovely');
        $this->actingAsUser($this->requester)->postJson($url, ['stars' => 1])
            ->assertStatus(409)->assertJsonPath('message', 'You have already rated this exchange.');
        $this->actingAsUser($this->requester)->postJson($url, ['stars' => 9])->assertStatus(422);

        $this->actingAsUser($this->donor)->postJson('/api/items/'.$this->item->id.'/confirm-handover');
        $this->actingAsUser($this->donor)->postJson($url, ['stars' => 2])->assertCreated();

        $this->assertEquals(4.0, $this->donor->fresh()->rating_avg);
        $this->assertSame(1, $this->donor->fresh()->rating_count);
        $this->actingAsUser($this->otherRequester)->getJson('/api/users/'.$this->donor->id.'/ratings')
            ->assertJsonCount(1, 'data')->assertJsonPath('data.0.stars', 4);
    }
}
