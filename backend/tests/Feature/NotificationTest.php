<?php

namespace Tests\Feature;

use App\Models\AdminNotification;

class NotificationTest extends ShareLoopTestCase
{
    public function test_guests_cannot_view_notifications(): void
    {
        $this->getJson('/api/notifications')->assertUnauthorized();
    }

    public function test_users_can_fetch_relevant_notifications(): void
    {
        $user = $this->makeUser(['donation_count' => 0]);
        $donor = $this->makeUser(['donation_count' => 5]);

        // Broadcast to all
        AdminNotification::create([
            'title' => 'System Update',
            'message' => 'ShareLoop platform maintenance completed.',
            'target_type' => 'all',
            'channel' => 'in_app',
            'sent_by' => $this->makeAdmin()->id,
            'recipients_count' => 10,
        ]);

        // Targeted to donors only
        AdminNotification::create([
            'title' => 'Donor Appreciation',
            'message' => 'Thank you for your generous donations.',
            'target_type' => 'donors',
            'channel' => 'in_app',
            'sent_by' => $this->makeAdmin()->id,
            'recipients_count' => 5,
        ]);

        // Targeted to specific user
        AdminNotification::create([
            'title' => 'Personal Note',
            'message' => 'Specific message for you.',
            'target_type' => 'specific',
            'target_user_ids' => [$user->id],
            'channel' => 'in_app',
            'sent_by' => $this->makeAdmin()->id,
            'recipients_count' => 1,
        ]);

        // Regular non-donor user gets 'all' and their 'specific' notification, not 'donors'
        $response = $this->actingAsUser($user)->getJson('/api/notifications');
        $response->assertOk()->assertJsonCount(2, 'data');
        $titles = collect($response->json('data'))->pluck('title')->all();
        $this->assertContains('Personal Note', $titles);
        $this->assertContains('System Update', $titles);
        $this->assertNotContains('Donor Appreciation', $titles);

        // Donor gets 'all' and 'donors' notification, not the specific notification meant for $user
        $donorResponse = $this->actingAsUser($donor)->getJson('/api/notifications');
        $donorResponse->assertOk()->assertJsonCount(2, 'data');
        $donorTitles = collect($donorResponse->json('data'))->pluck('title')->all();
        $this->assertContains('Donor Appreciation', $donorTitles);
        $this->assertContains('System Update', $donorTitles);
        $this->assertNotContains('Personal Note', $donorTitles);
    }
}
