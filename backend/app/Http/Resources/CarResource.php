<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CarResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'host_id' => $this->host_id,
            'make' => $this->make,
            'model' => $this->model,
            'year' => $this->year,
            'trim' => $this->trim,
            'plate_number' => $this->plate_number,
            'transmission' => $this->transmission,
            'fuel_type' => $this->fuel_type,
            'seats' => $this->seats,
            'doors' => $this->doors,
            'daily_price' => $this->daily_price,
            'weekly_discount_pct' => $this->weekly_discount_pct,
            'monthly_discount_pct' => $this->monthly_discount_pct,
            'dynamic_pricing_enabled' => $this->dynamic_pricing_enabled,
            'description' => $this->description,
            'features' => $this->features,
            'location' => [
                'lat' => $this->lat,
                'lng' => $this->lng,
                'address' => $this->address,
                'city' => $this->city,
                'country' => $this->country,
            ],
            'mileage_limit_per_day' => $this->mileage_limit_per_day,
            'excess_mileage_fee' => $this->excess_mileage_fee,
            'fuel_policy' => $this->fuel_policy,
            'smoking_allowed' => $this->smoking_allowed,
            'pets_allowed' => $this->pets_allowed,
            'status' => $this->status,
            'average_rating' => $this->average_rating,
            'total_reviews' => $this->total_reviews ?? 0,
            'photos' => CarPhotoResource::collection($this->whenLoaded('photos')),
            'host' => new UserSummaryResource($this->whenLoaded('host')),
            'reviews' => ReviewResource::collection($this->whenLoaded('reviews')),
            'distance' => $this->when(isset($this->distance), fn () => round($this->distance, 1)),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
