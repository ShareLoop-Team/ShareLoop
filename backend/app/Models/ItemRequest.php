<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Either a standalone "need" (item_id null, visible to every signed-in user)
 * or a request for a specific give-away item (private to the requester and
 * that item's donor).
 */
class ItemRequest extends Model
{
    use HasFactory, HasUuids;

    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';

    protected $fillable = [
        'requester_id', 'item_id', 'item_name', 'description', 'reason', 'notes',
        'category', 'district', 'city',
    ];

    protected $attributes = [
        'item_name' => '',
        'notes' => '',
        'city' => '',
        'status' => self::STATUS_PENDING,
        'is_hidden' => false,
    ];

    protected function casts(): array
    {
        return ['is_hidden' => 'boolean'];
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requester_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    /** Public needs, the viewer's own requests, and requests on the viewer's items. */
    public function scopeVisibleTo(Builder $query, User $viewer): Builder
    {
        if ($viewer->isAdmin()) {
            return $query;
        }

        return $query->where(function ($q) use ($viewer) {
            $q->where(fn ($q) => $q->whereNull('item_id')->where('is_hidden', false))
                ->orWhere('requester_id', $viewer->id)
                ->orWhereIn('item_id', Item::query()->select('id')->where('donor_id', $viewer->id));
        });
    }

    public function isVisibleTo(User $viewer): bool
    {
        if ($viewer->isAdmin() || $this->requester_id === $viewer->id) {
            return true;
        }
        if ($this->item_id === null) {
            return ! $this->is_hidden;
        }

        return $this->item?->donor_id === $viewer->id;
    }
}
