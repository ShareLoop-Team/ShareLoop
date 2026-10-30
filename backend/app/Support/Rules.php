<?php

namespace App\Support;

use App\Models\Category;
use Illuminate\Validation\Rule;

/** Validation rules shared by several endpoints (mirror the old DB checks). */
final class Rules
{
    public const PHONE = 'regex:/^\+?[0-9 ]{7,20}$/';

    public static function district(): array
    {
        return ['required', 'string', Rule::in(config('shareloop.districts'))];
    }

    public static function city(): array
    {
        return ['nullable', 'string', 'max:80'];
    }

    public static function activeCategory(): array
    {
        return ['required', 'string', Rule::in(Category::activeNames())];
    }

    public static function displayName(): array
    {
        return ['required', 'string', 'max:80', 'not_regex:/^\s*$/'];
    }

    public static function phone(): array
    {
        return ['required', 'string', self::PHONE];
    }

    public static function messages(): array
    {
        return [
            'phone.regex' => 'Enter a valid phone number (digits only, e.g. 0771234567).',
            'district.in' => 'Choose a district from the list.',
            'category.in' => 'Choose a category from the list.',
            'condition.in' => 'Choose a condition: New, Good or Used.',
            'email.unique' => 'An account already exists for that email. Please sign in.',
            'photos.max' => 'You can add up to :max photos.',
            'photos.*.max' => 'Each photo must be 5 MB or smaller.',
            'photos.*.mimes' => 'Photos must be JPEG, PNG or WebP.',
            'photos.*.image' => 'Photos must be JPEG, PNG or WebP.',
        ];
    }
}
