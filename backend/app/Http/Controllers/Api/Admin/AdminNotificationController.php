<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminNotification;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminNotificationController extends Controller
{
    public function index(): JsonResponse
    {
        $notifications = AdminNotification::with('sender:id,display_name')
            ->latest()
            ->paginate(15);

        return response()->json($notifications);
    }

    public function broadcast(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:160'],
            'message' => ['required', 'string', 'max:2000'],
            'target_type' => ['required', Rule::in(['all', 'donors', 'requesters', 'specific'])],
            'target_user_ids' => ['nullable', 'array'],
            'channel' => ['required', Rule::in(['in_app', 'email', 'push', 'all'])],
        ]);

        $query = User::where('status', User::STATUS_ACTIVE)->where('is_banned', false);
        if ($data['target_type'] === 'donors') {
            $query->where('donation_count', '>', 0);
        } elseif ($data['target_type'] === 'requesters') {
            $query->has('itemRequests');
        } elseif ($data['target_type'] === 'specific' && ! empty($data['target_user_ids'])) {
            $query->whereIn('id', $data['target_user_ids']);
        }

        $recipientCount = $query->count();

        $notification = AdminNotification::create([
            'title' => $data['title'],
            'message' => $data['message'],
            'target_type' => $data['target_type'],
            'target_user_ids' => $data['target_user_ids'] ?? null,
            'channel' => $data['channel'],
            'sent_by' => $request->user()->id,
            'recipients_count' => $recipientCount,
        ]);

        AuditLogger::log(
            action: 'notification.broadcast',
            entity: $notification,
            newValues: [
                'target' => $data['target_type'],
                'channel' => $data['channel'],
                'recipients' => $recipientCount,
            ],
            description: "Broadcasted announcement: '{$data['title']}' to {$recipientCount} users via {$data['channel']}"
        );

        return response()->json([
            'message' => "Broadcast queued successfully to {$recipientCount} recipient(s).",
            'notification' => $notification,
        ], 201);
    }
}
