<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Exchange */
class ExchangeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'item_id' => $this->item_id,
            'request_id' => $this->request_id,
            'item_title' => $this->item_title,
            'donor_id' => $this->donor_id,
            'requester_id' => $this->requester_id,
            'status' => $this->status,
            'donor_confirmed_at' => $this->donor_confirmed_at?->toIso8601String(),
            'requester_confirmed_at' => $this->requester_confirmed_at?->toIso8601String(),
            'completed_at' => $this->completed_at?->toIso8601String(),
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
