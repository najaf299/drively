<?php

namespace Database\Seeders;

use App\Models\Car;
use App\Models\CarPhoto;
use App\Models\User;
use Illuminate\Database\Seeder;

class CarSeeder extends Seeder
{
    public function run(): void
    {
        $hosts = User::where('role', 'host')->get();

        $carData = [
            ['make' => 'Toyota', 'model' => 'Camry', 'year' => 2024, 'fuel_type' => 'petrol', 'daily_price' => 55.00, 'city' => 'Dubai', 'country' => 'AE'],
            ['make' => 'BMW', 'model' => '3 Series', 'year' => 2023, 'fuel_type' => 'petrol', 'daily_price' => 120.00, 'city' => 'Dubai', 'country' => 'AE'],
            ['make' => 'Tesla', 'model' => 'Model 3', 'year' => 2024, 'fuel_type' => 'electric', 'daily_price' => 95.00, 'city' => 'Abu Dhabi', 'country' => 'AE'],
            ['make' => 'Mercedes', 'model' => 'E-Class', 'year' => 2023, 'fuel_type' => 'petrol', 'daily_price' => 150.00, 'city' => 'Dubai', 'country' => 'AE'],
            ['make' => 'Honda', 'model' => 'CR-V', 'year' => 2024, 'fuel_type' => 'hybrid', 'daily_price' => 70.00, 'city' => 'Riyadh', 'country' => 'SA'],
            ['make' => 'Hyundai', 'model' => 'Tucson', 'year' => 2023, 'fuel_type' => 'petrol', 'daily_price' => 50.00, 'city' => 'Jeddah', 'country' => 'SA'],
            ['make' => 'Ford', 'model' => 'Mustang', 'year' => 2024, 'fuel_type' => 'petrol', 'daily_price' => 180.00, 'city' => 'Dubai', 'country' => 'AE'],
            ['make' => 'Nissan', 'model' => 'Patrol', 'year' => 2023, 'fuel_type' => 'petrol', 'daily_price' => 130.00, 'city' => 'Abu Dhabi', 'country' => 'AE'],
            ['make' => 'Toyota', 'model' => 'Land Cruiser', 'year' => 2024, 'fuel_type' => 'diesel', 'daily_price' => 200.00, 'city' => 'Dubai', 'country' => 'AE'],
            ['make' => 'Kia', 'model' => 'Sportage', 'year' => 2023, 'fuel_type' => 'petrol', 'daily_price' => 45.00, 'city' => 'Doha', 'country' => 'QA'],
            ['make' => 'Tesla', 'model' => 'Model Y', 'year' => 2024, 'fuel_type' => 'electric', 'daily_price' => 110.00, 'city' => 'Dubai', 'country' => 'AE'],
            ['make' => 'Range Rover', 'model' => 'Sport', 'year' => 2023, 'fuel_type' => 'petrol', 'daily_price' => 250.00, 'city' => 'Dubai', 'country' => 'AE'],
        ];

        $cities = [
            'Dubai' => ['lat' => 25.2048, 'lng' => 55.2708],
            'Abu Dhabi' => ['lat' => 24.4539, 'lng' => 54.3773],
            'Riyadh' => ['lat' => 24.7136, 'lng' => 46.6753],
            'Jeddah' => ['lat' => 21.4858, 'lng' => 39.1925],
            'Doha' => ['lat' => 25.2854, 'lng' => 51.5310],
        ];

        foreach ($carData as $index => $data) {
            $host = $hosts[$index % count($hosts)];
            $cityCoords = $cities[$data['city']];

            $car = Car::create(array_merge($data, [
                'host_id' => $host->id,
                'plate_number' => strtoupper(fake()->bothify('??-####')),
                'transmission' => fake()->randomElement(['automatic', 'manual']),
                'seats' => fake()->randomElement([4, 5, 7]),
                'doors' => fake()->randomElement([2, 4]),
                'weekly_discount_pct' => fake()->randomFloat(2, 5, 15),
                'monthly_discount_pct' => fake()->randomFloat(2, 15, 30),
                'description' => fake()->paragraph(2),
                'features' => fake()->randomElements(
                    ['bluetooth', 'gps', 'backup_camera', 'heated_seats', 'sunroof', 'apple_carplay', 'android_auto', 'cruise_control', 'parking_sensors', 'keyless_entry'],
                    fake()->numberBetween(3, 7)
                ),
                'lat' => $cityCoords['lat'] + fake()->randomFloat(4, -0.03, 0.03),
                'lng' => $cityCoords['lng'] + fake()->randomFloat(4, -0.03, 0.03),
                'address' => fake()->streetAddress(),
                'mileage_limit_per_day' => fake()->randomElement([200, 300, 500]),
                'excess_mileage_fee' => fake()->randomFloat(2, 0.25, 1.00),
                'fuel_policy' => 'full_to_full',
                'smoking_allowed' => false,
                'pets_allowed' => fake()->boolean(30),
                'status' => 'active',
                'average_rating' => fake()->randomFloat(2, 3.8, 5.0),
                'total_reviews' => fake()->numberBetween(0, 25),
            ]));

            for ($p = 0; $p < fake()->numberBetween(3, 6); $p++) {
                CarPhoto::create([
                    'car_id' => $car->id,
                    'url' => "https://picsum.photos/seed/{$car->id}-{$p}/800/600",
                    'order' => $p,
                    'is_cover' => $p === 0,
                ]);
            }
        }
    }
}
