<?php

namespace Database\Factories;

use App\Models\Car;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class CarFactory extends Factory
{
    protected $model = Car::class;

    public function definition(): array
    {
        $makes = [
            'Toyota' => ['Camry', 'Corolla', 'RAV4', 'Highlander', 'Prius'],
            'Honda' => ['Civic', 'Accord', 'CR-V', 'Pilot', 'HR-V'],
            'BMW' => ['3 Series', '5 Series', 'X3', 'X5', 'M3'],
            'Mercedes' => ['C-Class', 'E-Class', 'GLC', 'GLE', 'A-Class'],
            'Tesla' => ['Model 3', 'Model Y', 'Model S', 'Model X'],
            'Ford' => ['Mustang', 'Explorer', 'F-150', 'Bronco', 'Escape'],
            'Hyundai' => ['Elantra', 'Tucson', 'Sonata', 'Santa Fe', 'Kona'],
            'Nissan' => ['Altima', 'Rogue', 'Sentra', 'Pathfinder', 'Leaf'],
        ];

        $make = fake()->randomElement(array_keys($makes));
        $model = fake()->randomElement($makes[$make]);

        $features = fake()->randomElements(
            ['bluetooth', 'gps', 'backup_camera', 'heated_seats', 'sunroof',
             'apple_carplay', 'android_auto', 'cruise_control', 'lane_assist',
             'parking_sensors', 'keyless_entry', 'leather_seats', 'usb_ports',
             'wifi_hotspot', 'adaptive_cruise', 'blind_spot_monitor'],
            fake()->numberBetween(3, 8)
        );

        $cities = [
            ['city' => 'Dubai', 'country' => 'AE', 'lat' => 25.2048, 'lng' => 55.2708],
            ['city' => 'Abu Dhabi', 'country' => 'AE', 'lat' => 24.4539, 'lng' => 54.3773],
            ['city' => 'Riyadh', 'country' => 'SA', 'lat' => 24.7136, 'lng' => 46.6753],
            ['city' => 'Jeddah', 'country' => 'SA', 'lat' => 21.4858, 'lng' => 39.1925],
            ['city' => 'Cairo', 'country' => 'EG', 'lat' => 30.0444, 'lng' => 31.2357],
            ['city' => 'Amman', 'country' => 'JO', 'lat' => 31.9454, 'lng' => 35.9284],
            ['city' => 'Beirut', 'country' => 'LB', 'lat' => 33.8938, 'lng' => 35.5018],
            ['city' => 'Doha', 'country' => 'QA', 'lat' => 25.2854, 'lng' => 51.5310],
        ];

        $location = fake()->randomElement($cities);

        return [
            'host_id' => User::factory()->host(),
            'make' => $make,
            'model' => $model,
            'year' => fake()->numberBetween(2018, (int) date('Y')),
            'trim' => fake()->optional(0.5)->randomElement(['Sport', 'Touring', 'Limited', 'SE', 'XLE']),
            'plate_number' => strtoupper(fake()->bothify('??-####')),
            'transmission' => fake()->randomElement(['automatic', 'manual']),
            'fuel_type' => fake()->randomElement(['petrol', 'diesel', 'electric', 'hybrid']),
            'seats' => fake()->randomElement([2, 4, 5, 7]),
            'doors' => fake()->randomElement([2, 4]),
            'daily_price' => fake()->randomFloat(2, 25, 300),
            'weekly_discount_pct' => fake()->randomFloat(2, 5, 15),
            'monthly_discount_pct' => fake()->randomFloat(2, 15, 30),
            'dynamic_pricing_enabled' => fake()->boolean(30),
            'description' => fake()->paragraph(2),
            'features' => $features,
            'lat' => $location['lat'] + fake()->randomFloat(4, -0.05, 0.05),
            'lng' => $location['lng'] + fake()->randomFloat(4, -0.05, 0.05),
            'address' => fake()->streetAddress(),
            'city' => $location['city'],
            'country' => $location['country'],
            'mileage_limit_per_day' => fake()->randomElement([200, 300, 500, null]),
            'excess_mileage_fee' => fake()->randomFloat(2, 0.25, 1.50),
            'fuel_policy' => fake()->randomElement(['full_to_full', 'full_to_empty', 'same_level']),
            'smoking_allowed' => fake()->boolean(20),
            'pets_allowed' => fake()->boolean(30),
            'status' => 'active',
            'average_rating' => fake()->randomFloat(2, 3.5, 5.0),
            'total_reviews' => fake()->numberBetween(0, 30),
        ];
    }

    public function draft(): static
    {
        return $this->state(fn () => ['status' => 'draft']);
    }

    public function electric(): static
    {
        return $this->state(fn () => [
            'make' => 'Tesla',
            'model' => fake()->randomElement(['Model 3', 'Model Y', 'Model S']),
            'fuel_type' => 'electric',
            'transmission' => 'automatic',
        ]);
    }
}
