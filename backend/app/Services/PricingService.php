<?php

namespace App\Services;

use App\Models\Car;

class PricingService
{
    public function getSuggestedPrice(Car $car): float
    {
        $basePrice = match ($car->fuel_type?->value ?? $car->fuel_type) {
            'electric' => 75.0,
            'hybrid' => 65.0,
            'diesel' => 58.0,
            default => 55.0,
        };

        $yearMultiplier = match (true) {
            $car->year >= (int) date('Y') => 1.35,
            $car->year >= (int) date('Y') - 1 => 1.25,
            $car->year >= (int) date('Y') - 2 => 1.15,
            $car->year >= (int) date('Y') - 5 => 1.0,
            default => 0.85,
        };

        $basePrice *= $yearMultiplier;

        if ($car->seats > 5) {
            $basePrice *= 1.15;
        }

        if ($car->transmission?->value === 'automatic' || $car->transmission === 'automatic') {
            $basePrice *= 1.05;
        }

        return round($basePrice, 2);
    }

    public function applyDynamicPricing(float $basePrice, float $demandMultiplier): float
    {
        $multiplier = max(0.8, min(2.0, $demandMultiplier));
        return round($basePrice * $multiplier, 2);
    }

    public function calculateWeeklyDiscount(float $dailyRate, int $days): float
    {
        if ($days >= 30) return round($dailyRate * $days * 0.25, 2);
        if ($days >= 7) return round($dailyRate * $days * 0.10, 2);
        return 0;
    }
}
