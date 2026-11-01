<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\BlacklistedIp;
use App\Models\SecurityLog;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\SecurityService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminSecurityController extends Controller
{
    public function __construct(protected SecurityService $security) {}

    public function index(): JsonResponse
    {
        $recentSecurityLogs = SecurityLog::with('user:id,display_name,email')
            ->latest()
            ->limit(30)
            ->get();

        $blacklistedIps = BlacklistedIp::with('blocker:id,display_name')->latest()->get();

        // Detect suspicious accounts: multiple active tokens or rapid failed logins
        $highTokenUsers = User::withCount('tokens')
            ->having('tokens_count', '>=', 3)
            ->orderByDesc('tokens_count')
            ->limit(10)
            ->get(['id', 'display_name', 'email', 'status', 'is_banned', 'created_at']);

        $failedLoginsCount = SecurityLog::where('event_type', 'failed_login')
            ->where('created_at', '>=', now()->subHours(24))
            ->count();

        return response()->json([
            'security_logs' => $recentSecurityLogs,
            'blacklisted_ips' => $blacklistedIps,
            'multi_device_accounts' => $highTokenUsers,
            'metrics_24h' => [
                'failed_logins' => $failedLoginsCount,
                'blacklisted_ips_count' => $blacklistedIps->count(),
            ],
        ]);
    }

    public function addBlacklistedIp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'ip_address' => ['required', 'ip'],
            'reason' => ['required', 'string', 'max:255'],
            'duration_hours' => ['nullable', 'integer', 'min:1'],
        ]);

        $ip = $this->security->blacklistIp(
            ip: $data['ip_address'],
            reason: $data['reason'],
            blockedBy: $request->user()->id,
            durationHours: $data['duration_hours'] ?? null
        );

        AuditLogger::log(
            action: 'security.ip_blacklisted',
            entity: $ip,
            newValues: $ip->toArray(),
            description: "IP {$ip->ip_address} blacklisted by admin. Reason: {$ip->reason}"
        );

        return response()->json(['message' => 'IP address blacklisted.', 'ip' => $ip]);
    }

    public function removeBlacklistedIp(string $id): JsonResponse
    {
        $ip = BlacklistedIp::findOrFail($id);

        AuditLogger::log(
            action: 'security.ip_unblocked',
            entity: $ip,
            oldValues: $ip->toArray(),
            description: "IP {$ip->ip_address} removed from blacklist"
        );

        $ip->delete();

        return response()->json(['message' => 'IP address unblocked successfully.']);
    }

    public function revokeUserSessions(string $userId): JsonResponse
    {
        $user = User::findOrFail($userId);
        $count = $this->security->forceLogout($user);

        return response()->json(['message' => "Successfully revoked {$count} active sessions."]);
    }
}
