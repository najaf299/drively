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
            'status' => $this->status,
            'mileage_start' => $this->mileage_start,
            'mileage_end' => $this->mileage_end,
            'fuel_level_start' => $this->fuel_level_start,
            'fuel_level_end' => $this->fuel_level_end,
            'started_at' => $this->started_at,
            'ended_at' => $this->ended_at,
            'extended' => $this->extended,
            'extension_days' => $this->extension_days,
        ];
    }
}
