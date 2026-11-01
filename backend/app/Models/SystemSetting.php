<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SystemSetting extends Model
{
    protected $primaryKey = 'key';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'key',
        'value',
        'type',
        'group',
        'description',
        'updated_by',
    ];

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public static function get(string $key, mixed $default = null): mixed
    {
        $setting = static::query()->find($key);
        if (! $setting) {
            return $default;
        }

        return match ($setting->type) {
            'boolean' => filter_var($setting->value, FILTER_VALIDATE_BOOLEAN),
            'integer' => (int) $setting->value,
            'json' => json_decode($setting->value, true) ?? $default,
            default => $setting->value,
        };
    }

    public static function set(string $key, mixed $value, ?string $group = 'general', ?string $userId = null): void
    {
        $type = 'string';
        $storedValue = $value;

        if (is_bool($value)) {
            $type = 'boolean';
            $storedValue = $value ? '1' : '0';
        } elseif (is_int($value)) {
            $type = 'integer';
            $storedValue = (string) $value;
        } elseif (is_array($value) || is_object($value)) {
            $type = 'json';
            $storedValue = json_encode($value);
        }

        static::query()->updateOrCreate(
            ['key' => $key],
            [
                'value' => $storedValue,
                'type' => $type,
                'group' => $group,
                'updated_by' => $userId,
            ]
        );
    }
}
