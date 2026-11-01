<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AdminDatabaseController extends Controller
{
    protected array $allowedTables = [
        'users',
        'items',
        'item_requests',
        'exchanges',
        'ratings',
        'categories',
        'reports',
        'audit_logs',
        'security_logs',
        'blacklisted_ips',
        'system_settings',
        'admin_notifications',
        'api_metrics',
        'admin_roles',
        'admin_permissions',
    ];

    public function tables(): JsonResponse
    {
        $tableInfo = [];

        foreach ($this->allowedTables as $table) {
            if (Schema::hasTable($table)) {
                $columns = Schema::getColumnListing($table);
                $count = DB::table($table)->count();
                $tableInfo[] = [
                    'table_name' => $table,
                    'row_count' => $count,
                    'columns' => $columns,
                ];
            }
        }

        return response()->json($tableInfo);
    }

    public function queryTable(Request $request, string $table): JsonResponse
    {
        if (! in_array($table, $this->allowedTables, true)) {
            return response()->json(['message' => 'Unauthorized or restricted table access.'], 403);
        }

        $query = DB::table($table);

        if ($request->filled('search') && $request->filled('column')) {
            $column = $request->input('column');
            if (Schema::hasColumn($table, $column)) {
                $query->where($column, 'like', '%' . $request->input('search') . '%');
            }
        }

        $sortColumn = $request->input('sort_by');
        $sortDir = $request->input('sort_dir', 'desc');
        if ($sortColumn && Schema::hasColumn($table, $sortColumn)) {
            $query->orderBy($sortColumn, $sortDir);
        }

        $perPage = min(50, (int) $request->input('per_page', 15));
        $records = $query->paginate($perPage);

        return response()->json([
            'table' => $table,
            'columns' => Schema::getColumnListing($table),
            'records' => $records,
        ]);
    }
}
