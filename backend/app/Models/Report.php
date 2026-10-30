<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** A user's report of an item, request or user, for admins to review. */
class Report extends Model
{
    use HasUuids;

    public const STATUS_OPEN = 'open';

    protected $guarded = [];

    protected $attributes = ['status' => self::STATUS_OPEN, 'details' => ''];

    protected function casts(): array
    {
        return ['resolved_at' => 'datetime'];
    }
}
