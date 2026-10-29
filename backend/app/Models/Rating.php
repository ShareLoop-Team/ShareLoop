<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** 1-5 stars left by one party of a confirmed handover for the other. */
class Rating extends Model
{
    use HasUuids;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['stars' => 'integer'];
    }
}
