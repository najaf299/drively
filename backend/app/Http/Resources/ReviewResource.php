<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReviewResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'booking_id' => $this->booking_id,
            'type' => $this->type,
            'rating' => $this->rating,
            'cleanliness_rating' => $this->cleanliness_rating,
            'communication_rating' => $this->communication_rating,
            'accuracy_rating' => $this->accuracy_rating,
            'pickup_rating' => $this->pickup_rating,
            'comment' => $this->comment,
            'tags' => $this->tags,
            'photo_urls' => $this->photo_urls,
            'is_public' => $this->is_public,
            'reviewer' => new UserSummaryResource($this->whenLoaded('reviewer')),
            'reviewee' => new UserSummaryResource($this->whenLoaded('reviewee')),
            'car' => $this->whenLoaded('car', fn () => [
                'id' => $this->car->id,
                'make' => $this->car->make,
                'model' => $this->car->model,
                'year' => $this->car->year,
            ]),
            'created_at' => $this->created_at,
        ];
    }
}
