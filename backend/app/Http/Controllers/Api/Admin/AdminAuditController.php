<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminAuditController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = AuditLog::with('user:id,display_name,email');

        if ($request->filled('action')) {
            $query->where('action', 'like', '%' . $request->input('action') . '%');
        }

        if ($request->filled('entity_type')) {
            $query->where('entity_type', $request->input('entity_type'));
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->input('user_id'));
        }

        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->input('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->input('date_to'));
        }

        $query->orderBy('created_at', 'desc');
        $perPage = min(100, (int) $request->input('per_page', 20));

        $actions = AuditLog::select('action')->distinct()->pluck('action');

        return response()->json([
            'logs' => $query->paginate($perPage),
            'available_actions' => $actions,
        ]);
    }

    public function show(string $id): JsonResponse
    {
        $log = AuditLog::with('user')->findOrFail($id);

        return response()->json($log);
    }
}
