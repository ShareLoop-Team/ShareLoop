<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** A browsing category. Retired categories are hidden, never deleted. */
class Category extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = ['id', 'name', 'icon_name', 'sort_order', 'is_active'];

    protected $attributes = ['icon_name' => 'category', 'sort_order' => 0, 'is_active' => true];

    protected function casts(): array
    {
        return ['is_active' => 'boolean', 'sort_order' => 'integer'];
    }

    /** @return list<string> names of the categories posts may use */
    public static function activeNames(): array
    {
        return static::query()->where('is_active', true)->pluck('name')->all();
    }
}
