<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Models\Report;
use App\Models\User;
use App\Services\AiModerationService;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminModerationController extends Controller
{
    public function __construct(protected AiModerationService $aiModeration) {}

    public function index(Request $request): JsonResponse
    {
        $query = Report::with([
            'reporter:id,display_name,email',
            'item:id,title,donor_id,is_hidden,moderation_status,ai_flagged',
            'request:id,item_name,requester_id,is_hidden',
            'reportedUser:id,display_name,email,status,is_banned',
            'resolver:id,display_name',
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('reason')) {
            $query->where('reason', $request->input('reason'));
        }

        $query->orderBy('created_at', 'desc');
        $perPage = min(100, (int) $request->input('per_page', 15));

        return response()->json($query->paginate($perPage));
    }

    public function resolve(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'action' => ['required', Rule::in(['dismiss', 'remove_content', 'suspend_user', 'ban_user'])],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        $report = Report::with(['item', 'reportedUser'])->findOrFail($id);

        switch ($data['action']) {
            case 'dismiss':
                $report->status = 'dismissed';
                break;

            case 'remove_content':
                $report->status = 'actioned';
                if ($report->item) {
                    $report->item->update([
                        'is_hidden' => true,
                        'moderation_status' => Item::MODERATION_REJECTED,
                        'moderation_notes' => 'Removed following community report: ' . ($data['note'] ?? 'Violation of guidelines'),
                    ]);
                }
                if ($report->request) {
                    $report->request->update(['is_hidden' => true, 'status' => 'rejected']);
                }
                break;

            case 'suspend_user':
                $report->status = 'actioned';
                $targetUser = $report->reportedUser ?: ($report->item?->donor_id ? User::find($report->item->donor_id) : null);
                if ($targetUser) {
                    $targetUser->update(['status' => User::STATUS_SUSPENDED]);
                    $targetUser->tokens()->delete();
                }
                break;

            case 'ban_user':
                $report->status = 'actioned';
                $targetUser = $report->reportedUser ?: ($report->item?->donor_id ? User::find($report->item->donor_id) : null);
                if ($targetUser) {
                    $targetUser->update([
                        'is_banned' => true,
                        'status' => User::STATUS_SUSPENDED,
                        'banned_at' => now(),
                        'ban_reason' => $data['note'] ?? 'Banned via moderation report',
                    ]);
                    $targetUser->tokens()->delete();
                }
                break;
        }

        $report->resolved_by = $request->user()->id;
        $report->resolved_at = now();
        $report->resolution_note = $data['note'] ?? null;
        $report->save();

        AuditLogger::log(
            action: 'moderation.resolve',
            entity: $report,
            newValues: ['action' => $data['action'], 'note' => $data['note'] ?? null],
            description: "Report #{$report->id} resolved with action: {$data['action']}"
        );

        return response()->json([
            'message' => 'Report resolved successfully.',
            'report' => $report,
        ]);
    }
}
