<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AdminNotification extends Model
{
    use HasUuids;

    protected $fillable = [
        'title',
        'message',
        'target_type',
        'target_user_ids',
        'channel',
        'sent_by',
        'recipients_count',
    ];

    protected function casts(): array
    {
        return [
            'target_user_ids' => 'array',
            'recipients_count' => 'integer',
        ];
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sent_by');
    }
}
