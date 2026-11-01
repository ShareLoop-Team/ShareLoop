<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** A "Give Away" post. image_paths are object names on the photo disk. */
class Item extends Model
{
    use HasFactory, HasUuids;

    public const STATUS_ACTIVE = 'active';
    public const STATUS_PENDING_HANDOVER = 'pending_handover';
    public const STATUS_COMPLETED = 'completed';

    public const MODERATION_APPROVED = 'approved';
    public const MODERATION_PENDING = 'pending';
    public const MODERATION_REJECTED = 'rejected';
    public const MODERATION_ARCHIVED = 'archived';

    protected $fillable = [
        'donor_id', 'title', 'description', 'condition', 'category',
        'district', 'city', 'image_paths',
        'moderation_status', 'moderation_notes', 'moderated_by',
        'moderated_at', 'ai_toxicity_score', 'ai_scam_score', 'ai_flagged',
    ];

    protected $attributes = [
        'city' => '',
        'image_paths' => '[]',
        'status' => self::STATUS_ACTIVE,
        'is_hidden' => false,
        'moderation_status' => self::MODERATION_APPROVED,
        'ai_toxicity_score' => 0,
        'ai_scam_score' => 0,
        'ai_flagged' => false,
    ];

    protected function casts(): array
    {
        return [
            'image_paths' => 'array',
            'is_hidden' => 'boolean',
            'ai_flagged' => 'boolean',
            'ai_toxicity_score' => 'integer',
            'ai_scam_score' => 'integer',
            'moderated_at' => 'datetime',
        ];
    }

    public function moderator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'moderated_by');
    }

    public function donor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'donor_id');
    }

    public function selectedRequest(): BelongsTo
    {
        return $this->belongsTo(ItemRequest::class, 'selected_request_id');
    }

    public function requests(): HasMany
    {
        return $this->hasMany(ItemRequest::class, 'item_id');
    }

    /** Items [viewer] may open: visible ones, plus their own and (admins) all. */
    public function scopeVisibleTo(Builder $query, User $viewer): Builder
    {
        if ($viewer->isAdmin()) {
            return $query;
        }

        return $query->where(fn ($q) => $q->where('is_hidden', false)->orWhere('donor_id', $viewer->id));
    }

    public function isVisibleTo(User $viewer): bool
    {
        return ! $this->is_hidden || $this->donor_id === $viewer->id || $viewer->isAdmin();
    }
}
