<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EarningResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'booking_id' => $this->booking_id,
            'host_id' => $this->host_id,
            'gross_amount' => $this->gross_amount,
            'platform_commission' => $this->platform_commission,
            'insurance_fee' => $this->insurance_fee,
            'net_amount' => $this->net_amount,
            'status' => $this->status,
            'paid_at' => $this->paid_at?->toISOString(),
            'booking' => new BookingResource($this->whenLoaded('booking')),
            'created_at' => $this->created_at,
        ];
    }
}
