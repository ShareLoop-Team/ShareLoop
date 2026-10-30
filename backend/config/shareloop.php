<?php

// ShareLoop domain settings shared by validation, seeders and tests.
// Keep these lists in step with lib/core/constants/app_constants.dart.

return [

    'districts' => [
        'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle',
        'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle',
        'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala',
        'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura',
        'Trincomalee', 'Vavuniya',
    ],

    'conditions' => ['New', 'Good', 'Used'],

    // Seeded categories: [id, name, icon_name, sort_order].
    'categories' => [
        ['books', 'Educational Books', 'book', 10],
        ['supplies', 'School Supplies', 'edit', 20],
        ['clothes', 'Clothes', 'checkroom', 30],
        ['shoes', 'Shoes', 'sports_soccer', 40],
        ['electronics', 'Electronics', 'devices', 50],
        ['household', 'Household Items', 'chair', 60],
        ['other', 'Other', 'category', 70],
    ],

    'report_reasons' => ['spam', 'inappropriate', 'prohibited_item', 'scam', 'other'],

    'photos' => [
        // Storage disk and folder for item photos (private; served through
        // short-lived signed URLs).
        'disk' => env('SHARELOOP_PHOTO_DISK', 'local'),
        'folder' => 'item-images',
        'max_per_item' => 5,
        'max_kilobytes' => 5120,
        'mimes' => ['jpeg', 'jpg', 'png', 'webp'],
        'url_lifetime_minutes' => 60,
    ],

    // Feed page size and caps on list endpoints.
    'page_size' => 50,
    'max_page_size' => 100,
    'request_list_limit' => 200,
    'admin_list_limit' => 500,

    // One-time email codes (sign-up, code sign-in, password reset).
    'otp' => [
        'length' => 6,
        'lifetime_minutes' => (int) env('SHARELOOP_OTP_MINUTES', 10),
        'max_attempts' => 5,
        'resend_seconds' => 60,
    ],

    // "Sign in with Google": the OAuth client IDs whose ID tokens we accept
    // (comma-separated: the Web client, plus Android/iOS ones if any).
    'google' => [
        'client_ids' => array_values(array_filter(array_map('trim', explode(',', (string) env('GOOGLE_CLIENT_IDS', ''))))),
        'certs_url' => 'https://www.googleapis.com/oauth2/v3/certs',
    ],

    // "Continue with Facebook": the Meta app whose user access tokens we
    // accept. The secret stays on the server (used for debug_token).
    'facebook' => [
        'app_id' => trim((string) env('FACEBOOK_APP_ID', '')),
        'app_secret' => trim((string) env('FACEBOOK_APP_SECRET', '')),
        'graph_url' => 'https://graph.facebook.com/v21.0',
    ],

    // Days an API token stays valid.
    'token_lifetime_days' => (int) env('SHARELOOP_TOKEN_DAYS', 30),
];
