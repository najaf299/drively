<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Car;
use App\Models\User;
use Illuminate\Support\Str;

class BookingService
{
    public function calculatePricing(Car $car, int $days, ?string $promoCode = null): array
    {
        $dailyRate = $car->daily_price;
        $subtotal = $dailyRate * $days;

        $discount = 0;
        if ($days >= 30 && $car->monthly_discount_pct > 0) {
            $discount = $subtotal * ($car->monthly_discount_pct / 100);
        } elseif ($days >= 7 && $car->weekly_discount_pct > 0) {
            $discount = $subtotal * ($car->weekly_discount_pct / 100);
        }

        $serviceFee = ($subtotal - $discount) * 0.10;
        $tax = ($subtotal - $discount + $serviceFee) * 0.05;
        $total = $subtotal - $discount + $serviceFee + $tax;

        return [
            'daily_rate' => $dailyRate,
            'total_days' => $days,
            'subtotal' => round($subtotal, 2),
            'discount' => round($discount, 2),
            'service_fee' => round($serviceFee, 2),
            'tax' => round($tax, 2),
            'total_amount' => round($total, 2),
        ];
    }

    public function createBooking(array $data): Booking
    {
        $data['reference'] = 'DRV-' . strtoupper(Str::random(8));
        return Booking::create($data);
    }

    public function cancelBooking(Booking $booking, string $reason): Booking
    {
        $booking->update([
            'status' => 'cancelled',
            'cancellation_reason' => $reason,
            'cancelled_at' => now(),
        ]);

        return $booking;
    }
}
