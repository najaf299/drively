<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'phone' => fake()->unique()->e164PhoneNumber(),
            'email_verified_at' => now(),
            'phone_verified_at' => now(),
            'password' => Hash::make('password'),
            'role' => 'customer',
            'kyc_status' => 'none',
            'avatar_url' => fake()->imageUrl(200, 200, 'people'),
            'average_rating' => fake()->randomFloat(2, 3.5, 5.0),
            'total_trips' => fake()->numberBetween(0, 50),
            'preferred_language' => 'en',
            'preferred_currency' => 'USD',
            'preferred_units' => 'km',
            'notification_settings' => ['push' => true, 'email' => true, 'sms' => false],
            'is_suspended' => false,
            'remember_token' => Str::random(10),
        ];
    }

    public function host(): static
    {
        return $this->state(fn () => ['role' => 'host', 'kyc_status' => 'approved']);
    }

    public function admin(): static
    {
        return $this->state(fn () => ['role' => 'admin', 'kyc_status' => 'approved']);
    }

    public function kycApproved(): static
    {
        return $this->state(fn () => ['kyc_status' => 'approved']);
    }

    public function suspended(): static
    {
        return $this->state(fn () => [
            'is_suspended' => true,
            'suspension_reason' => 'Policy violation',
        ]);
    }

    public function unverified(): static
    {
        return $this->state(fn () => [
            'email_verified_at' => null,
            'phone_verified_at' => null,
        ]);
    }
}
