<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Rating */
class RatingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'exchange_id' => $this->exchange_id,
            'item_id' => $this->item_id,
            'rater_id' => $this->rater_id,
            'ratee_id' => $this->ratee_id,
            'stars' => $this->stars,
            'comment' => $this->comment,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
