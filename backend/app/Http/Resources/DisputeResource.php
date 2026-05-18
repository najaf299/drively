<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DisputeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'booking_id' => $this->booking_id,
            'reporter_id' => $this->reporter_id,
            'type' => $this->type,
            'description' => $this->description,
            'evidence_urls' => $this->evidence_urls,
            'status' => $this->status,
            'resolution' => $this->resolution,
            'refund_amount' => $this->refund_amount,
            'resolved_at' => $this->resolved_at?->toISOString(),
            'booking' => $this->whenLoaded('booking'),
            'reporter' => new UserSummaryResource($this->whenLoaded('reporter')),
            'resolver' => new UserSummaryResource($this->whenLoaded('resolver')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
