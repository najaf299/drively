<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TripResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'booking_id' => $this->booking_id,
            'status' => $this->status,
            'mileage_start' => $this->mileage_start,
            'mileage_end' => $this->mileage_end,
            'total_mileage' => $this->totalMileage(),
            'fuel_level_start' => $this->fuel_level_start,
            'fuel_level_end' => $this->fuel_level_end,
            'started_at' => $this->started_at?->toISOString(),
            'ended_at' => $this->ended_at?->toISOString(),
            'last_known_location' => [
                'lat' => $this->last_known_lat,
                'lng' => $this->last_known_lng,
                'updated_at' => $this->location_updated_at?->toISOString(),
            ],
            'extended' => $this->extended,
            'extension_days' => $this->extension_days,
            'is_overdue' => $this->when($this->booking, fn () => $this->isOverdue()),
            'booking' => new BookingResource($this->whenLoaded('booking')),
            'inspections' => $this->whenLoaded('inspections'),
            'created_at' => $this->created_at,
        ];
    }
}
