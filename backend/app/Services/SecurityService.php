<?php

namespace App\Services;

use App\Models\BlacklistedIp;
use App\Models\SecurityLog;
use App\Models\User;
use Illuminate\Support\Facades\Request;

class SecurityService
{
    /**
     * Check if the current IP address is blacklisted.
     */
    public function isIpBlacklisted(?string $ip = null): bool
    {
        $checkIp = $ip ?: Request::ip();
        if (! $checkIp) {
            return false;
        }

        try {
            if (! \Illuminate\Support\Facades\Schema::hasTable('blacklisted_ips')) {
                return false;
            }

            $entry = BlacklistedIp::where('ip_address', $checkIp)->first();
            if (! $entry) {
                return false;
            }

            return $entry->isCurrentlyBlocked();
        } catch (\Throwable $e) {
            return false;
        }
    }

    /**
     * Record a security log event.
     */
    public function recordEvent(string $type, string $severity = 'info', ?string $userId = null, array $details = []): SecurityLog
    {
        return SecurityLog::create([
            'user_id' => $userId,
            'event_type' => $type,
            'severity' => $severity,
            'ip_address' => Request::ip(),
            'user_agent' => Request::userAgent(),
            'details' => $details,
        ]);
    }

    /**
     * Revoke all API sessions / tokens for a user (force logout).
     */
    public function forceLogout(User $user): int
    {
        $deleted = $user->tokens()->delete();

        $this->recordEvent('force_logout', 'warning', $user->id, [
            'tokens_revoked' => $deleted,
            'reason' => 'Administrative force logout',
        ]);

        return $deleted;
    }

    /**
     * Blacklist an IP address.
     */
    public function blacklistIp(string $ip, string $reason, ?string $blockedBy = null, ?int $durationHours = null): BlacklistedIp
    {
        $blockedUntil = $durationHours ? now()->addHours($durationHours) : null;

        return BlacklistedIp::updateOrCreate(
            ['ip_address' => $ip],
            [
                'reason' => $reason,
                'blocked_by' => $blockedBy,
                'blocked_until' => $blockedUntil,
            ]
        );
    }
}
