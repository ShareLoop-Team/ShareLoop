<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** A hashed one-time code emailed to someone (see App\Services\EmailOtpService). */
class EmailOtp extends Model
{
    public const PURPOSE_REGISTER = 'register';
    public const PURPOSE_LOGIN = 'login';
    public const PURPOSE_RESET = 'reset';

    public const PURPOSES = [self::PURPOSE_REGISTER, self::PURPOSE_LOGIN, self::PURPOSE_RESET];

    protected $guarded = [];

    protected $hidden = ['code_hash'];

    protected function casts(): array
    {
        return [
            'attempts' => 'integer',
            'expires_at' => 'datetime',
            'consumed_at' => 'datetime',
        ];
    }
}
