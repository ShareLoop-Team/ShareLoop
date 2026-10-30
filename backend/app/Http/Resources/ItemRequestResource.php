<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use App\Services\PhotoStorage;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\ItemRequest */
class ItemRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'requester_id' => $this->requester_id,
            'requester' => [
                'display_name' => $this->requester?->display_name ?? '',
                'avatar_url' => $this->requester?->avatar_path ? PhotoStorage::url($this->requester->avatar_path) : null,
            ],
            'item_id' => $this->item_id,
            'item_name' => $this->item_name,
            'description' => $this->description,
            'reason' => $this->reason,
            'notes' => $this->notes,
            'category' => $this->category,
            'district' => $this->district,
            'city' => $this->city,
            'status' => $this->status,
            'is_hidden' => (bool) $this->is_hidden,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
