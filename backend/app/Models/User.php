<?php

namespace App\Models;

use Illuminate\Contracts\Auth\CanResetPassword;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * A ShareLoop account and public profile. Email and phone are contact
 * details: only shown to the user, admins, and the other party of a live
 * exchange (see UserResource).
 */
class User extends Authenticatable implements CanResetPassword
{
    use HasApiTokens, HasFactory, HasUuids, Notifiable;

    public const STATUS_ACTIVE = 'active';
    public const STATUS_SUSPENDED = 'suspended';

    protected $fillable = [
        'display_name', 'email', 'password', 'phone', 'district', 'city',
    ];

    protected $hidden = ['password', 'remember_token', 'google_id', 'facebook_id'];

    protected $attributes = [
        'city' => '',
        'donation_count' => 0,
        'rating_avg' => 0,
        'rating_count' => 0,
        'is_admin' => false,
        'status' => self::STATUS_ACTIVE,
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'donation_count' => 'integer',
            'rating_avg' => 'float',
            'rating_count' => 'integer',
            'is_admin' => 'boolean',
        ];
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }

    public function isAdmin(): bool
    {
        return $this->is_admin && $this->isActive();
    }

    public function items(): HasMany
    {
        return $this->hasMany(Item::class, 'donor_id');
    }

    public function itemRequests(): HasMany
    {
        return $this->hasMany(ItemRequest::class, 'requester_id');
    }

    /** Whether this user and [otherId] are the two parties of a live exchange. */
    public function sharesExchangeWith(string $otherId): bool
    {
        return Exchange::query()
            ->where('status', '!=', Exchange::STATUS_CANCELLED)
            ->where(function ($q) use ($otherId) {
                $q->where(fn ($q) => $q->where('donor_id', $this->id)->where('requester_id', $otherId))
                    ->orWhere(fn ($q) => $q->where('requester_id', $this->id)->where('donor_id', $otherId));
            })
            ->exists();
    }

    /** Whether [viewer] may see this user's email and phone. */
    public function contactsVisibleTo(?User $viewer): bool
    {
        if ($viewer === null) {
            return false;
        }

        return $viewer->id === $this->id
            || $viewer->isAdmin()
            || $viewer->sharesExchangeWith($this->id);
    }

    /** Recomputes rating_avg / rating_count from the ratings table. */
    public function refreshRatingSummary(): void
    {
        $query = Rating::query()->where('ratee_id', $this->id);
        $count = (clone $query)->count();
        $avg = $count > 0 ? round((float) (clone $query)->avg('stars'), 2) : 0;
        $this->forceFill(['rating_count' => $count, 'rating_avg' => $avg])->save();
    }
}
