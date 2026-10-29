<?php

namespace App\Http\Resources;

use App\Services\PhotoStorage;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Item */
class ItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $paths = $this->image_paths ?? [];

        return [
            'id' => $this->id,
            'donor_id' => $this->donor_id,
            'donor' => [
                'display_name' => $this->donor?->display_name ?? '',
                'donation_count' => $this->donor?->donation_count ?? 0,
            ],
            'title' => $this->title,
            'description' => $this->description,
            'condition' => $this->condition,
            'category' => $this->category,
            'district' => $this->district,
            'city' => $this->city,
            'image_paths' => $paths,
            'image_urls' => array_map(fn (string $p) => PhotoStorage::url($p), $paths),
            'status' => $this->status,
            'selected_requester_id' => $this->selectedRequest?->requester_id,
            'is_hidden' => (bool) $this->is_hidden,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
