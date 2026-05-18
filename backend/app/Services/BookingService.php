<?php

namespace App\Services;

use App\Events\BookingCancelled;
use App\Events\BookingCreated;
use App\Models\Booking;
use App\Models\Car;
use App\Models\PromoCode;
use App\Models\User;
use Illuminate\Support\Str;

class BookingService
{
    public function calculatePricing(Car $car, string $pickupAt, string $returnAt, ?string $promoCode = null, array $addons = []): array
    {
        $pickup = new \DateTime($pickupAt);
        $return = new \DateTime($returnAt);
        $days = max(1, $pickup->diff($return)->days);

        $dailyRate = $car->daily_price;
        $subtotal = $dailyRate * $days;

        $discount = 0;
        if ($days >= 30 && $car->monthly_discount_pct) {
            $discount = round($subtotal * ($car->monthly_discount_pct / 100), 2);
        } elseif ($days >= 7 && $car->weekly_discount_pct) {
            $discount = round($subtotal * ($car->weekly_discount_pct / 100), 2);
        }

        if ($promoCode) {
            $promo = PromoCode::where('code', $promoCode)->first();
            if ($promo && $promo->isValid()) {
                $promoDiscount = $promo->calculateDiscount($subtotal - $discount);
                $discount += $promoDiscount;
            }
        }

        $addonsTotal = collect($addons)->sum('price');
        $serviceFee = round(($subtotal - $discount + $addonsTotal) * 0.10, 2);
        $tax = round(($subtotal - $discount + $addonsTotal + $serviceFee) * 0.05, 2);
        $totalAmount = $subtotal - $discount + $addonsTotal + $serviceFee + $tax;

        return [
            'daily_rate' => $dailyRate,
            'total_days' => $days,
            'subtotal' => $subtotal,
            'discount' => $discount,
            'addons_total' => $addonsTotal,
            'service_fee' => $serviceFee,
            'tax' => $tax,
            'total_amount' => round($totalAmount, 2),
        ];
    }

    public function createBooking(User $customer, array $data): Booking
    {
        $car = Car::findOrFail($data['car_id']);

        if (!$car->isAvailableFor($data['pickup_at'], $data['return_at'])) {
            throw new \Exception('Car is not available for the selected dates.');
        }

        $pricing = $this->calculatePricing(
            $car,
            $data['pickup_at'],
            $data['return_at'],
            $data['promo_code'] ?? null,
            $data['addons'] ?? []
        );

        $booking = Booking::create([
            'reference' => 'DRV-' . strtoupper(Str::random(8)),
            'car_id' => $car->id,
            'customer_id' => $customer->id,
            'pickup_at' => $data['pickup_at'],
            'return_at' => $data['return_at'],
            'pickup_address' => $data['pickup_address'] ?? $car->address,
            'daily_rate' => $pricing['daily_rate'],
            'total_days' => $pricing['total_days'],
            'subtotal' => $pricing['subtotal'],
            'discount' => $pricing['discount'],
            'addons_total' => $pricing['addons_total'],
            'service_fee' => $pricing['service_fee'],
            'tax' => $pricing['tax'],
            'total_amount' => $pricing['total_amount'],
            'addons' => $data['addons'] ?? [],
            'booking_type' => $car->instant_booking ? 'instant' : 'request',
            'status' => 'pending',
            'host_response_deadline' => now()->addHours(24),
        ]);

        event(new BookingCreated($booking));

        return $booking->load('car', 'customer');
    }

    public function approveBooking(Booking $booking): Booking
    {
        $booking->update([
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);

        return $booking->fresh();
    }

    public function declineBooking(Booking $booking, string $reason): Booking
    {
        $booking->update([
            'status' => 'declined',
            'cancellation_reason' => $reason,
        ]);

        return $booking->fresh();
    }

    public function cancelBooking(Booking $booking, string $reason): Booking
    {
        $booking->update([
            'status' => 'cancelled',
            'cancellation_reason' => $reason,
            'cancelled_at' => now(),
        ]);

        event(new BookingCancelled($booking));

        return $booking->fresh();
    }

    public function completeBooking(Booking $booking): Booking
    {
        $booking->update(['status' => 'completed']);
        return $booking->fresh();
    }
}
