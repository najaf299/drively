<?php

namespace Database\Seeders;

use App\Models\Booking;
use App\Models\Car;
use App\Models\Earning;
use App\Models\Payment;
use App\Models\Review;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class BookingSeeder extends Seeder
{
    public function run(): void
    {
        $customers = User::where('role', 'customer')->get();
        $cars = Car::where('status', 'active')->get();

        if ($customers->isEmpty() || $cars->isEmpty()) {
            return;
        }

        // Create some completed bookings with reviews
        for ($i = 0; $i < 8; $i++) {
            $car = $cars->random();
            $customer = $customers->random();
            $days = fake()->numberBetween(1, 7);
            $dailyRate = $car->daily_price;
            $subtotal = $dailyRate * $days;
            $serviceFee = round($subtotal * 0.10, 2);
            $tax = round(($subtotal + $serviceFee) * 0.05, 2);
            $total = $subtotal + $serviceFee + $tax;

            $booking = Booking::create([
                'reference' => 'DRV-' . strtoupper(Str::random(8)),
                'car_id' => $car->id,
                'customer_id' => $customer->id,
                'pickup_at' => now()->subDays(fake()->numberBetween(10, 60)),
                'return_at' => now()->subDays(fake()->numberBetween(1, 9)),
                'daily_rate' => $dailyRate,
                'total_days' => $days,
                'subtotal' => $subtotal,
                'service_fee' => $serviceFee,
                'tax' => $tax,
                'discount' => 0,
                'addons_total' => 0,
                'total_amount' => $total,
                'addons' => [],
                'pickup_address' => fake()->streetAddress(),
                'booking_type' => 'instant',
                'status' => 'completed',
                'confirmed_at' => now()->subDays(60),
            ]);

            Payment::create([
                'booking_id' => $booking->id,
                'method' => 'card',
                'amount' => $total,
                'currency' => 'USD',
                'status' => 'succeeded',
                'stripe_payment_intent_id' => 'pi_seed_' . Str::random(16),
                'paid_at' => $booking->confirmed_at,
            ]);

            $grossAmount = $total;
            $commission = round($grossAmount * 0.15, 2);
            $insurance = round($grossAmount * 0.05, 2);

            Earning::create([
                'host_id' => $car->host_id,
                'booking_id' => $booking->id,
                'gross_amount' => $grossAmount,
                'platform_commission' => $commission,
                'insurance_fee' => $insurance,
                'net_amount' => $grossAmount - $commission - $insurance,
                'status' => 'paid',
                'paid_at' => $booking->return_at,
            ]);

            if (fake()->boolean(70)) {
                Review::create([
                    'booking_id' => $booking->id,
                    'reviewer_id' => $customer->id,
                    'reviewee_id' => $car->host_id,
                    'car_id' => $car->id,
                    'type' => 'car',
                    'rating' => fake()->numberBetween(3, 5),
                    'cleanliness_rating' => fake()->numberBetween(3, 5),
                    'communication_rating' => fake()->numberBetween(3, 5),
                    'accuracy_rating' => fake()->numberBetween(3, 5),
                    'comment' => fake()->sentence(10),
                    'is_public' => true,
                ]);
            }
        }

        // Create a few pending bookings
        for ($i = 0; $i < 3; $i++) {
            $car = $cars->random();
            $customer = $customers->random();
            $days = fake()->numberBetween(1, 5);
            $dailyRate = $car->daily_price;
            $subtotal = $dailyRate * $days;
            $serviceFee = round($subtotal * 0.10, 2);
            $tax = round(($subtotal + $serviceFee) * 0.05, 2);

            Booking::create([
                'reference' => 'DRV-' . strtoupper(Str::random(8)),
                'car_id' => $car->id,
                'customer_id' => $customer->id,
                'pickup_at' => now()->addDays(fake()->numberBetween(2, 14)),
                'return_at' => now()->addDays(fake()->numberBetween(15, 28)),
                'daily_rate' => $dailyRate,
                'total_days' => $days,
                'subtotal' => $subtotal,
                'service_fee' => $serviceFee,
                'tax' => $tax,
                'discount' => 0,
                'addons_total' => 0,
                'total_amount' => $subtotal + $serviceFee + $tax,
                'addons' => [],
                'pickup_address' => fake()->streetAddress(),
                'booking_type' => 'request',
                'status' => 'pending',
                'host_response_deadline' => now()->addHours(24),
            ]);
        }
    }
}
