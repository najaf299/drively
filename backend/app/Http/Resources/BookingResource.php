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
            'car_id' => $this->car_id,
            'customer_id' => $this->customer_id,
            'status' => $this->status,
            'booking_type' => $this->booking_type,
            'pickup_at' => $this->pickup_at?->toISOString(),
            'return_at' => $this->return_at?->toISOString(),
            'pickup_address' => $this->pickup_address,
            'pricing' => [
                'daily_rate' => $this->daily_rate,
                'total_days' => $this->total_days,
                'subtotal' => $this->subtotal,
                'addons_total' => $this->addons_total,
                'service_fee' => $this->service_fee,
                'tax' => $this->tax,
                'discount' => $this->discount,
                'total_amount' => $this->total_amount,
            ],
            'addons' => $this->addons,
            'cancellation_reason' => $this->cancellation_reason,
            'confirmed_at' => $this->confirmed_at?->toISOString(),
            'cancelled_at' => $this->cancelled_at?->toISOString(),
            'host_response_deadline' => $this->host_response_deadline?->toISOString(),
            'car' => new CarResource($this->whenLoaded('car')),
            'customer' => new UserSummaryResource($this->whenLoaded('customer')),
            'payment' => $this->whenLoaded('payment'),
            'trip' => new TripResource($this->whenLoaded('trip')),
            'reviews' => ReviewResource::collection($this->whenLoaded('reviews')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
