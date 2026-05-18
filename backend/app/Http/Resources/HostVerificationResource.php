<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HostVerificationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'identity_status' => $this->identity_status,
            'identity_document_url' => $this->identity_document_url,
            'bank_status' => $this->bank_status,
            'bank_document_url' => $this->bank_document_url,
            'vehicle_status' => $this->vehicle_status,
            'vehicle_document_url' => $this->vehicle_document_url,
            'agreement_status' => $this->agreement_status,
            'is_complete' => $this->isComplete(),
            'completed_at' => $this->completed_at?->toISOString(),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
