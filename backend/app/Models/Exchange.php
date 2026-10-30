<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** The handover between a donor and the requester they selected. */
class Exchange extends Model
{
    use HasUuids;

    public const STATUS_PENDING = 'pending';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_CANCELLED = 'cancelled';

    protected $guarded = [];

    protected $attributes = ['status' => self::STATUS_PENDING];

    protected function casts(): array
    {
        return [
            'donor_confirmed_at' => 'datetime',
            'requester_confirmed_at' => 'datetime',
            'completed_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    public function involves(User $user): bool
    {
        return $user->id === $this->donor_id || $user->id === $this->requester_id;
    }
}
