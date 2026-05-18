<?php

namespace Database\Seeders;

use App\Models\HostVerification;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin user
        $admin = User::firstOrCreate(
            ['email' => 'admin@drivly.com'],
            [
                'name' => 'Admin User',
                'phone' => '+971500000001',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'kyc_status' => 'approved',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ]
        );
        $admin->assignRole('admin');
        Wallet::firstOrCreate(['user_id' => $admin->id], ['balance' => 0, 'currency' => 'USD']);

        // Host users
        $hosts = [
            ['name' => 'Ahmed Hassan', 'email' => 'ahmed@drivly.com', 'phone' => '+971500000002'],
            ['name' => 'Sara Al-Rashid', 'email' => 'sara@drivly.com', 'phone' => '+971500000003'],
            ['name' => 'Mohammed Ali', 'email' => 'mohammed@drivly.com', 'phone' => '+971500000004'],
        ];

        foreach ($hosts as $hostData) {
            $host = User::firstOrCreate(
                ['email' => $hostData['email']],
                array_merge($hostData, [
                    'password' => Hash::make('password'),
                    'role' => 'host',
                    'kyc_status' => 'approved',
                    'email_verified_at' => now(),
                    'phone_verified_at' => now(),
                    'average_rating' => fake()->randomFloat(2, 4.0, 5.0),
                    'total_trips' => fake()->numberBetween(10, 100),
                ])
            );
            $host->assignRole('host');
            Wallet::firstOrCreate(['user_id' => $host->id], ['balance' => fake()->randomFloat(2, 100, 5000), 'currency' => 'USD']);

            HostVerification::firstOrCreate(
                ['user_id' => $host->id],
                [
                    'identity_status' => 'approved',
                    'bank_status' => 'approved',
                    'vehicle_status' => 'approved',
                    'agreement_status' => 'signed',
                    'completed_at' => now()->subMonths(2),
                ]
            );
        }

        // Customer users
        $customers = [
            ['name' => 'John Smith', 'email' => 'john@example.com', 'phone' => '+971500000005'],
            ['name' => 'Fatima Al-Zahra', 'email' => 'fatima@example.com', 'phone' => '+971500000006'],
            ['name' => 'Omar Khan', 'email' => 'omar@example.com', 'phone' => '+971500000007'],
            ['name' => 'Layla Noor', 'email' => 'layla@example.com', 'phone' => '+971500000008'],
            ['name' => 'Yusuf Patel', 'email' => 'yusuf@example.com', 'phone' => '+971500000009'],
        ];

        foreach ($customers as $customerData) {
            $customer = User::firstOrCreate(
                ['email' => $customerData['email']],
                array_merge($customerData, [
                    'password' => Hash::make('password'),
                    'role' => 'customer',
                    'kyc_status' => fake()->randomElement(['none', 'approved', 'pending']),
                    'email_verified_at' => now(),
                    'phone_verified_at' => now(),
                    'average_rating' => fake()->randomFloat(2, 3.5, 5.0),
                    'total_trips' => fake()->numberBetween(0, 20),
                ])
            );
            $customer->assignRole('customer');
            Wallet::firstOrCreate(['user_id' => $customer->id], ['balance' => fake()->randomFloat(2, 0, 500), 'currency' => 'USD']);
        }
    }
}
