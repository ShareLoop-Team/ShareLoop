<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Report */
class ReportResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'reporter_id' => $this->reporter_id,
            'item_id' => $this->item_id,
            'request_id' => $this->request_id,
            'reported_user_id' => $this->reported_user_id,
            'reason' => $this->reason,
            'details' => $this->details,
            'status' => $this->status,
            'resolved_by' => $this->resolved_by,
            'resolved_at' => $this->resolved_at?->toIso8601String(),
            'resolution_note' => $this->resolution_note,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
