<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use App\Services\PhotoStorage;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Public profile. email/phone are null unless the viewer may see them
 * (themselves, an admin, or the other party of a live exchange).
 *
 * @mixin \App\Models\User
 */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $showContacts = $this->contactsVisibleTo($request->user());

        return [
            'id' => $this->id,
            'display_name' => $this->display_name,
            'email' => $showContacts ? $this->email : null,
            'phone' => $showContacts ? $this->phone : null,
            'district' => $this->district,
            'city' => $this->city,
            'avatar_url' => $this->avatar_path ? PhotoStorage::url($this->avatar_path) : null,
            'donation_count' => $this->donation_count,
            'rating_avg' => (float) $this->rating_avg,
            'rating_count' => $this->rating_count,
            'is_admin' => (bool) $this->is_admin,
            'status' => $this->status,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
