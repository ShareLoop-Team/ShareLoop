<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Services\AiModerationService;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminItemController extends Controller
{
    public function __construct(protected AiModerationService $aiModeration) {}

    public function index(Request $request): JsonResponse
    {
        $query = Item::with(['donor:id,display_name,email,district,phone', 'selectedRequest']);

        if ($request->filled('search')) {
            $search = '%' . $request->input('search') . '%';
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', $search)
                    ->orWhere('description', 'like', $search)
                    ->orWhere('city', 'like', $search);
            });
        }

        if ($request->filled('category')) {
            $query->where('category', $request->input('category'));
        }

        if ($request->filled('district')) {
            $query->where('district', $request->input('district'));
        }

        if ($request->filled('condition')) {
            $query->where('condition', $request->input('condition'));
        }

        if ($request->filled('moderation_status')) {
            $query->where('moderation_status', $request->input('moderation_status'));
        }

        if ($request->has('ai_flagged')) {
            $query->where('ai_flagged', $request->boolean('ai_flagged'));
        }

        if ($request->has('hidden')) {
            $query->where('is_hidden', $request->boolean('hidden'));
        }

        $query->orderBy('created_at', 'desc');
        $perPage = min(100, (int) $request->input('per_page', 15));

        return response()->json($query->paginate($perPage));
    }

    public function show(string $id): JsonResponse
    {
        $item = Item::with([
            'donor',
            'selectedRequest.requester',
            'requests.requester:id,display_name,email,district',
            'moderator:id,display_name',
        ])->findOrFail($id);

        return response()->json($item);
    }

    public function updateModeration(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'action' => ['required', Rule::in(['approve', 'reject', 'archive', 'toggle_hide'])],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        $item = Item::findOrFail($id);
        $oldState = [
            'moderation_status' => $item->moderation_status,
            'is_hidden' => $item->is_hidden,
        ];

        switch ($data['action']) {
            case 'approve':
                $item->moderation_status = Item::MODERATION_APPROVED;
                $item->is_hidden = false;
                break;
            case 'reject':
                $item->moderation_status = Item::MODERATION_REJECTED;
                $item->is_hidden = true;
                break;
            case 'archive':
                $item->moderation_status = Item::MODERATION_ARCHIVED;
                $item->is_hidden = true;
                break;
            case 'toggle_hide':
                $item->is_hidden = ! $item->is_hidden;
                break;
        }

        $item->moderation_notes = $data['notes'] ?? $item->moderation_notes;
        $item->moderated_by = $request->user()->id;
        $item->moderated_at = now();
        $item->save();

        AuditLogger::log(
            action: 'item.' . $data['action'],
            entity: $item,
            oldValues: $oldState,
            newValues: ['moderation_status' => $item->moderation_status, 'is_hidden' => $item->is_hidden],
            description: $data['notes'] ?? ("Item moderation action: {$data['action']}")
        );

        return response()->json(['message' => 'Listing updated successfully.', 'item' => $item]);
    }

    public function runAiScan(string $id): JsonResponse
    {
        $item = Item::findOrFail($id);
        $result = $this->aiModeration->scan($item->title, $item->description);

        $item->ai_toxicity_score = $result['toxicity_score'];
        $item->ai_scam_score = $result['scam_score'];
        $item->ai_flagged = $result['is_flagged'];
        $item->save();

        AuditLogger::log(
            action: 'item.ai_scan',
            entity: $item,
            newValues: $result,
            description: "AI Moderation scan performed (Flagged: " . ($result['is_flagged'] ? 'Yes' : 'No') . ")"
        );

        return response()->json([
            'message' => 'AI scan complete.',
            'scan_results' => $result,
            'item' => $item,
        ]);
    }

    public function destroy(string $id): JsonResponse
    {
        $item = Item::findOrFail($id);

        AuditLogger::log(
            action: 'item.delete',
            entity: $item,
            oldValues: ['title' => $item->title, 'category' => $item->category],
            description: 'Item listing permanently deleted by admin'
        );

        $item->delete();

        return response()->json(['message' => 'Item deleted successfully.']);
    }
}
