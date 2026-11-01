<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ItemRequest;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminRequestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = ItemRequest::with(['requester:id,display_name,email,district', 'item:id,title,category,donor_id,status']);

        if ($request->filled('search')) {
            $search = '%' . $request->input('search') . '%';
            $query->where(function ($q) use ($search) {
                $q->where('item_name', 'like', $search)
                    ->orWhere('description', 'like', $search)
                    ->orWhere('reason', 'like', $search);
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('category')) {
            $query->where('category', $request->input('category'));
        }

        if ($request->filled('district')) {
            $query->where('district', $request->input('district'));
        }

        $query->orderBy('created_at', 'desc');
        $perPage = min(100, (int) $request->input('per_page', 15));

        return response()->json($query->paginate($perPage));
    }

    public function show(string $id): JsonResponse
    {
        $req = ItemRequest::with([
            'requester',
            'item.donor',
        ])->findOrFail($id);

        return response()->json($req);
    }

    public function updateStatus(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'action' => ['required', Rule::in(['approve', 'reject', 'cancel', 'escalate', 'toggle_hide'])],
            'note' => ['nullable', 'string', 'max:500'],
        ]);

        $itemRequest = ItemRequest::findOrFail($id);
        $oldStatus = $itemRequest->status;

        switch ($data['action']) {
            case 'approve':
                $itemRequest->status = 'approved';
                break;
            case 'reject':
                $itemRequest->status = 'rejected';
                break;
            case 'cancel':
                $itemRequest->status = 'cancelled';
                break;
            case 'escalate':
                $itemRequest->status = 'escalated';
                break;
            case 'toggle_hide':
                $itemRequest->is_hidden = ! $itemRequest->is_hidden;
                break;
        }

        $itemRequest->save();

        AuditLogger::log(
            action: 'request.' . $data['action'],
            entity: $itemRequest,
            oldValues: ['status' => $oldStatus],
            newValues: ['status' => $itemRequest->status, 'is_hidden' => $itemRequest->is_hidden],
            description: $data['note'] ?? "Request action: {$data['action']}"
        );

        return response()->json(['message' => 'Request updated successfully.', 'request' => $itemRequest]);
    }
}
