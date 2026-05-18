<?php

namespace App\Services;

use App\Models\Car;

class PricingService
{
    public function getSuggestedPrice(Car $car): float
    {
        $basePrice = match ($car->fuel_type) {
            'electric' => 75.0,
            'hybrid' => 65.0,
            default => 55.0,
        };

        if ($car->year >= (int) date('Y') - 2) {
            $basePrice *= 1.2;
        }

        if ($car->seats > 5) {
            $basePrice *= 1.15;
        }

        return round($basePrice, 2);
    }

    public function applyDynamicPricing(float $basePrice, float $demandMultiplier): float
    {
        $multiplier = max(0.8, min(2.0, $demandMultiplier));
        return round($basePrice * $multiplier, 2);
    }
}
