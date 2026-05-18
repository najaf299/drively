<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BookingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'reference' => $this->reference,
            'car' => new CarResource($this->whenLoaded('car')),
            'customer' => new UserSummaryResource($this->whenLoaded('customer')),
            'pickup_at' => $this->pickup_at,
            'return_at' => $this->return_at,
            'daily_rate' => $this->daily_rate,
            'total_days' => $this->total_days,
            'subtotal' => $this->subtotal,
            'addons_total' => $this->addons_total,
            'service_fee' => $this->service_fee,
            'tax' => $this->tax,
            'discount' => $this->discount,
            'total_amount' => $this->total_amount,
            'addons' => $this->addons,
            'pickup_address' => $this->pickup_address,
            'booking_type' => $this->booking_type,
            'status' => $this->status,
            'payment' => new PaymentResource($this->whenLoaded('payment')),
            'trip' => new TripResource($this->whenLoaded('trip')),
            'created_at' => $this->created_at,
        ];
    }
}
