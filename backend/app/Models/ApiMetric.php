<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ApiMetric extends Model
{
    use HasUuids;

    protected $fillable = [
        'method',
        'endpoint',
        'status_code',
        'response_time_ms',
        'ip_address',
    ];

    protected function casts(): array
    {
        return [
            'status_code' => 'integer',
            'response_time_ms' => 'float',
        ];
    }
}
