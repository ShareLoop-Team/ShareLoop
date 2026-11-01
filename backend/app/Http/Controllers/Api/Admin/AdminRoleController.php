<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminPermission;
use App\Models\AdminRole;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminRoleController extends Controller
{
    public function index(): JsonResponse
    {
        $roles = AdminRole::with('permissions')->get();
        $permissions = AdminPermission::all()->groupBy('group');

        // Admin users
        $adminUsers = User::where(function ($q) {
            $q->where('is_admin', true)->orWhereNotNull('role_id');
        })->with('role')->get(['id', 'display_name', 'email', 'is_admin', 'role_id', 'status', 'created_at']);

        return response()->json([
            'roles' => $roles,
            'permissions_matrix' => $permissions,
            'admin_users' => $adminUsers,
        ]);
    }

    public function assignRole(Request $request, string $userId): JsonResponse
    {
        $data = $request->validate([
            'role_id' => ['nullable', 'exists:admin_roles,id'],
            'is_admin' => ['nullable', 'boolean'],
        ]);

        $user = User::findOrFail($userId);
        $oldState = ['role_id' => $user->role_id, 'is_admin' => $user->is_admin];

        $user->role_id = $data['role_id'] ?? null;
        if (isset($data['is_admin'])) {
            $user->is_admin = $data['is_admin'];
        }
        $user->save();

        AuditLogger::log(
            action: 'role.assign',
            entity: $user,
            oldValues: $oldState,
            newValues: ['role_id' => $user->role_id, 'is_admin' => $user->is_admin],
            description: "Updated administrative role for user {$user->display_name}"
        );

        return response()->json([
            'message' => 'Role assigned successfully.',
            'user' => $user->load('role'),
        ]);
    }

    public function updateRolePermissions(Request $request, string $roleId): JsonResponse
    {
        $role = AdminRole::findOrFail($roleId);

        if ($role->slug === 'super-admin') {
            return response()->json(['message' => 'Super Admin role permissions are immutable.'], 422);
        }

        $data = $request->validate([
            'permission_ids' => ['required', 'array'],
            'permission_ids.*' => ['exists:admin_permissions,id'],
        ]);

        $role->permissions()->sync($data['permission_ids']);

        AuditLogger::log(
            action: 'role.permissions_update',
            entity: $role,
            description: "Updated permissions matrix for role {$role->name}"
        );

        return response()->json([
            'message' => 'Role permissions updated successfully.',
            'role' => $role->load('permissions'),
        ]);
    }
}
