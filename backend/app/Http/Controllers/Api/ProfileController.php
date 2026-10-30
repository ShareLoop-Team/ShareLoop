<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Services\PhotoStorage;
use App\Support\Rules;
use Illuminate\Http\Request;

/** The signed-in user's own editable details. */
class ProfileController extends Controller
{
    public function update(Request $request): UserResource
    {
        $data = $request->validate([
            'name' => ['sometimes', ...Rules::displayName()],
            'phone' => ['sometimes', ...Rules::phone()],
            'district' => ['sometimes', ...Rules::district()],
            'city' => ['sometimes', ...Rules::city()],
        ], Rules::messages());

        $user = $request->user();
        if (array_key_exists('name', $data)) {
            $user->display_name = trim($data['name']);
        }
        if (array_key_exists('phone', $data)) {
            $user->phone = trim($data['phone']);
        }
        if (array_key_exists('district', $data)) {
            $user->district = $data['district'];
        }
        if (array_key_exists('city', $data)) {
            $user->city = trim($data['city'] ?? '');
        }
        $user->save();

        return new UserResource($user);
    }

    /** Replaces the signed-in user's profile photo. */
    public function updateAvatar(Request $request): UserResource
    {
        $photos = config('shareloop.photos');
        $request->validate([
            'photo' => ['required', 'file', 'image', 'mimes:'.implode(',', $photos['mimes']), 'max:'.$photos['max_kilobytes']],
        ]);
        $user = $request->user();
        $old = $user->avatar_path;
        $user->avatar_path = PhotoStorage::store($request->file('photo'), $user->id);
        $user->save();
        if ($old !== null) {
            PhotoStorage::delete([$old]);
        }

        return new UserResource($user);
    }
}
