<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Exchange;
use App\Models\Item;
use App\Models\Rating;
use App\Models\SecurityLog;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\SecurityService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    public function __construct(protected SecurityService $security) {}

    public function index(Request $request): JsonResponse
    {
        $query = User::with('role');

        if ($request->filled('search')) {
            $search = '%' . $request->input('search') . '%';
            $query->where(function ($q) use ($search) {
                $q->where('display_name', 'like', $search)
                    ->orWhere('email', 'like', $search)
                    ->orWhere('phone', 'like', $search);
            });
        }

        if ($request->filled('status')) {
            $status = $request->input('status');
            if ($status === 'banned') {
                $query->where('is_banned', true);
            } elseif ($status === 'suspended') {
                $query->where('status', User::STATUS_SUSPENDED)->where('is_banned', false);
            } elseif ($status === 'active') {
                $query->where('status', User::STATUS_ACTIVE)->where('is_banned', false);
            }
        }

        if ($request->filled('district')) {
            $query->where('district', $request->input('district'));
        }

        if ($request->filled('badge')) {
            $query->where('badge', $request->input('badge'));
        }

        $sortField = $request->input('sort_by', 'created_at');
        $sortDir = $request->input('sort_dir', 'desc');
        $query->orderBy($sortField, $sortDir);

        $perPage = min(100, (int) $request->input('per_page', 15));
        $users = $query->paginate($perPage);

        return response()->json($users);
    }

    public function show(string $id): JsonResponse
    {
        $user = User::with('role')->findOrFail($id);

        $donations = Item::where('donor_id', $user->id)->latest()->limit(20)->get();
        $receivedExchanges = Exchange::where('requester_id', $user->id)
            ->where('status', 'completed')
            ->latest()
            ->limit(20)
            ->get();

        $ratingsGiven = Rating::where('rater_id', $user->id)->latest()->limit(10)->get();
        $ratingsReceived = Rating::where('ratee_id', $user->id)->with('rater:id,display_name')->latest()->limit(10)->get();

        $auditLogs = AuditLog::where('entity_id', $user->id)->orWhere('user_id', $user->id)->latest()->limit(15)->get();
        $securityLogs = SecurityLog::where('user_id', $user->id)->latest()->limit(15)->get();

        return response()->json([
            'user' => $user,
            'donations' => $donations,
            'received_items' => $receivedExchanges,
            'ratings_received' => $ratingsReceived,
            'ratings_given' => $ratingsGiven,
            'audit_logs' => $auditLogs,
            'security_logs' => $securityLogs,
        ]);
    }

    public function updateStatus(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'action' => ['required', Rule::in(['activate', 'suspend', 'ban', 'verify'])],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $user = User::findOrFail($id);
        $oldState = ['status' => $user->status, 'is_banned' => $user->is_banned, 'is_verified' => $user->is_verified];

        switch ($data['action']) {
            case 'activate':
                $user->status = User::STATUS_ACTIVE;
                $user->is_banned = false;
                $user->ban_reason = null;
                break;
            case 'suspend':
                $user->status = User::STATUS_SUSPENDED;
                $user->tokens()->delete();
                break;
            case 'ban':
                $user->is_banned = true;
                $user->status = User::STATUS_SUSPENDED;
                $user->banned_at = now();
                $user->ban_reason = $data['reason'] ?? 'Banned by administrator';
                $user->tokens()->delete();
                break;
            case 'verify':
                $user->is_verified = ! $user->is_verified;
                break;
        }

        $user->save();

        AuditLogger::log(
            action: 'user.' . $data['action'],
            entity: $user,
            oldValues: $oldState,
            newValues: ['status' => $user->status, 'is_banned' => $user->is_banned, 'is_verified' => $user->is_verified],
            description: $data['reason'] ?? ('User account ' . $data['action'])
        );

        return response()->json(['message' => 'User updated successfully.', 'user' => $user]);
    }

    public function resetPassword(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'password' => ['required', 'string', 'min:6'],
        ]);

        $user = User::findOrFail($id);
        $user->password = Hash::make($data['password']);
        $user->save();

        $this->security->forceLogout($user);

        AuditLogger::log(
            action: 'user.password_reset',
            entity: $user,
            description: 'Password reset performed by admin'
        );

        return response()->json(['message' => 'Password reset successfully. Active sessions were revoked.']);
    }

    public function forceLogout(string $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $count = $this->security->forceLogout($user);

        AuditLogger::log(
            action: 'user.force_logout',
            entity: $user,
            description: "Revoked {$count} active authentication tokens"
        );

        return response()->json(['message' => "Force logout complete. {$count} tokens revoked."]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = User::findOrFail($id);
        if ($user->id === $request->user()->id) {
            return response()->json(['message' => 'Cannot delete your own admin account.'], 422);
        }

        AuditLogger::log(
            action: 'user.delete',
            entity: $user,
            oldValues: ['display_name' => $user->display_name, 'email' => $user->email],
            description: 'User permanently deleted by administrator'
        );

        $user->delete();

        return response()->json(['message' => 'User deleted successfully.']);
    }
}
