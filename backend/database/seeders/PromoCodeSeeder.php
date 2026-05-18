<?php

namespace Database\Seeders;

use App\Models\PromoCode;
use Illuminate\Database\Seeder;

class PromoCodeSeeder extends Seeder
{
    public function run(): void
    {
        $promoCodes = [
            [
                'code' => 'WELCOME20',
                'type' => 'percentage',
                'value' => 20,
                'max_discount' => 50,
                'min_booking_amount' => 100,
                'max_uses' => 1000,
                'max_uses_per_user' => 1,
                'valid_from' => now(),
                'valid_until' => now()->addYear(),
                'is_active' => true,
            ],
            [
                'code' => 'SAVE10',
                'type' => 'fixed',
                'value' => 10,
                'max_discount' => null,
                'min_booking_amount' => 50,
                'max_uses' => 500,
                'max_uses_per_user' => 3,
                'valid_from' => now(),
                'valid_until' => now()->addMonths(6),
                'is_active' => true,
            ],
            [
                'code' => 'SUMMER25',
                'type' => 'percentage',
                'value' => 25,
                'max_discount' => 100,
                'min_booking_amount' => 200,
                'max_uses' => 200,
                'max_uses_per_user' => 1,
                'valid_from' => now(),
                'valid_until' => now()->addMonths(3),
                'is_active' => true,
            ],
        ];

        foreach ($promoCodes as $promo) {
            PromoCode::firstOrCreate(['code' => $promo['code']], $promo);
        }
    }
}
