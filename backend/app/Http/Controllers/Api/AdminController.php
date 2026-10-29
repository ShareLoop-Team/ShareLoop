<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ItemRequestResource;
use App\Http\Resources\ItemResource;
use App\Http\Resources\ReportResource;
use App\Http\Resources\UserResource;
use App\Models\Item;
use App\Models\ItemRequest;
use App\Models\Report;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/** Moderation. Everything is reversible: users are suspended, posts hidden. */
class AdminController extends Controller
{
    /** Active users by default; ?status=suspended or ?status=all. */
    public function users(Request $request): AnonymousResourceCollection
    {
        $status = $request->input('status', User::STATUS_ACTIVE);
        $query = User::query()->latest()->limit(config('shareloop.admin_list_limit'));
        if ($status !== 'all') {
            $query->where('status', $status);
        }

        return UserResource::collection($query->get());
    }

    public function setUserStatus(Request $request, string $id): UserResource
    {
        $data = $request->validate([
            'status' => ['required', Rule::in([User::STATUS_ACTIVE, User::STATUS_SUSPENDED])],
        ]);
        if ($id === $request->user()->id) {
            abort(422, 'You cannot change your own account status.');
        }
        $user = User::query()->findOrFail($id);
        $user->forceFill(['status' => $data['status']])->save();
        if ($data['status'] === User::STATUS_SUSPENDED) {
            // Cut access immediately on every device.
            $user->tokens()->delete();
        }

        return new UserResource($user);
    }

    /** Visible posts by default; ?hidden=1 for hidden ones. */
    public function items(Request $request): AnonymousResourceCollection
    {
        $items = Item::query()
            ->with(['donor', 'selectedRequest'])
            ->where('is_hidden', $request->boolean('hidden'))
            ->orderByDesc('created_at')
            ->limit(200)
            ->get();

        return ItemResource::collection($items);
    }

    public function setItemHidden(Request $request, string $id): ItemResource
    {
        $data = $request->validate([
            'hidden' => ['required', 'boolean'],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);
        $item = Item::query()->findOrFail($id);
        $item->forceFill([
            'is_hidden' => $data['hidden'],
            'hidden_reason' => $data['hidden'] ? ($data['reason'] ?? null) : null,
        ])->save();

        return new ItemResource($item->load(['donor', 'selectedRequest']));
    }

    public function setRequestHidden(Request $request, string $id): ItemRequestResource
    {
        $data = $request->validate(['hidden' => ['required', 'boolean']]);
        $itemRequest = ItemRequest::query()->findOrFail($id);
        $itemRequest->forceFill(['is_hidden' => $data['hidden']])->save();

        return new ItemRequestResource($itemRequest->load('requester'));
    }

    public function resolveReport(Request $request, string $id): ReportResource
    {
        $data = $request->validate([
            'status' => ['required', Rule::in(['actioned', 'dismissed'])],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);
        $report = Report::query()->findOrFail($id);
        $report->forceFill([
            'status' => $data['status'],
            'resolved_by' => $request->user()->id,
            'resolved_at' => now(),
            'resolution_note' => $data['note'] ?? null,
        ])->save();

        return new ReportResource($report);
    }
}
