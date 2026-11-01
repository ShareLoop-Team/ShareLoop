<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BlacklistedIp extends Model
{
    use HasUuids;

    protected $fillable = [
        'ip_address',
        'reason',
        'blocked_by',
        'blocked_until',
    ];

    protected function casts(): array
    {
        return [
            'blocked_until' => 'datetime',
        ];
    }

    public function blocker(): BelongsTo
    {
        return $this->belongsTo(User::class, 'blocked_by');
    }

    public function isCurrentlyBlocked(): bool
    {
        return $this->blocked_until === null || $this->blocked_until->isFuture();
    }
}
