<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ReportResource;
use App\Models\Report;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/** Users report a post, request or user; admins resolve reports. */
class ReportController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $me = $request->user();
        $query = Report::query()->latest();
        if (! $me->isAdmin()) {
            $query->where('reporter_id', $me->id);
        } elseif ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        return ReportResource::collection($query->limit(200)->get());
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'item_id' => ['nullable', 'string', 'exists:items,id'],
            'request_id' => ['nullable', 'string', 'exists:item_requests,id'],
            'reported_user_id' => ['nullable', 'string', 'exists:users,id'],
            'reason' => ['required', Rule::in(config('shareloop.report_reasons'))],
            'details' => ['nullable', 'string', 'max:1000'],
        ]);
        $targets = array_filter([
            $data['item_id'] ?? null, $data['request_id'] ?? null, $data['reported_user_id'] ?? null,
        ]);
        if (count($targets) !== 1) {
            abort(422, 'Report exactly one post, request or user.');
        }
        $me = $request->user();

        $alreadyOpen = Report::query()
            ->where('reporter_id', $me->id)
            ->where('status', Report::STATUS_OPEN)
            ->where('item_id', $data['item_id'] ?? null)
            ->where('request_id', $data['request_id'] ?? null)
            ->where('reported_user_id', $data['reported_user_id'] ?? null)
            ->exists();
        if ($alreadyOpen) {
            abort(409, 'You have already reported this.');
        }

        $report = Report::create([
            'reporter_id' => $me->id,
            'item_id' => $data['item_id'] ?? null,
            'request_id' => $data['request_id'] ?? null,
            'reported_user_id' => $data['reported_user_id'] ?? null,
            'reason' => $data['reason'],
            'details' => trim($data['details'] ?? ''),
        ]);

        return (new ReportResource($report))->response()->setStatusCode(201);
    }
}
