<?php

namespace Database\Factories;

use App\Models\Booking;
use App\Models\Car;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class BookingFactory extends Factory
{
    protected $model = Booking::class;

    public function definition(): array
    {
        $pickupAt = fake()->dateTimeBetween('+1 day', '+30 days');
        $days = fake()->numberBetween(1, 14);
        $returnAt = (clone $pickupAt)->modify("+{$days} days");
        $dailyRate = fake()->randomFloat(2, 30, 200);
        $subtotal = $dailyRate * $days;
        $serviceFee = round($subtotal * 0.10, 2);
        $tax = round(($subtotal + $serviceFee) * 0.05, 2);

        return [
            'reference' => 'DRV-' . strtoupper(Str::random(8)),
            'car_id' => Car::factory(),
            'customer_id' => User::factory(),
            'pickup_at' => $pickupAt,
            'return_at' => $returnAt,
            'daily_rate' => $dailyRate,
            'total_days' => $days,
            'subtotal' => $subtotal,
            'addons_total' => 0,
            'service_fee' => $serviceFee,
            'tax' => $tax,
            'discount' => 0,
            'total_amount' => $subtotal + $serviceFee + $tax,
            'addons' => [],
            'pickup_address' => fake()->streetAddress(),
            'booking_type' => fake()->randomElement(['instant', 'request']),
            'status' => 'pending',
            'host_response_deadline' => now()->addHours(24),
        ];
    }

    public function confirmed(): static
    {
        return $this->state(fn () => [
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);
    }

    public function completed(): static
    {
        return $this->state(fn () => [
            'status' => 'completed',
            'confirmed_at' => now()->subDays(5),
            'pickup_at' => now()->subDays(4),
            'return_at' => now()->subDay(),
        ]);
    }

    public function active(): static
    {
        return $this->state(fn () => [
            'status' => 'active',
            'confirmed_at' => now()->subDays(2),
            'pickup_at' => now()->subDay(),
            'return_at' => now()->addDays(3),
        ]);
    }
}
