<?php

namespace Database\Seeders;

use App\Models\PlatformSetting;
use Illuminate\Database\Seeder;

class PlatformSettingSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            ['key' => 'platform_commission_pct', 'value' => '15', 'description' => 'Platform commission percentage on bookings'],
            ['key' => 'insurance_fee_pct', 'value' => '5', 'description' => 'Insurance fee percentage on bookings'],
            ['key' => 'service_fee_pct', 'value' => '10', 'description' => 'Service fee percentage charged to customers'],
            ['key' => 'tax_pct', 'value' => '5', 'description' => 'Tax percentage on bookings'],
            ['key' => 'host_response_deadline_hours', 'value' => '24', 'description' => 'Hours hosts have to respond to booking requests'],
            ['key' => 'max_booking_days', 'value' => '90', 'description' => 'Maximum number of days for a single booking'],
            ['key' => 'min_booking_hours', 'value' => '24', 'description' => 'Minimum booking duration in hours'],
            ['key' => 'cancellation_free_hours', 'value' => '48', 'description' => 'Hours before pickup for free cancellation'],
            ['key' => 'late_cancellation_fee_pct', 'value' => '50', 'description' => 'Late cancellation fee percentage'],
            ['key' => 'supported_currencies', 'value' => 'USD,AED,SAR,QAR,EGP', 'description' => 'Supported currencies'],
            ['key' => 'supported_languages', 'value' => 'en,ar,fr', 'description' => 'Supported languages'],
            ['key' => 'min_car_year', 'value' => '2015', 'description' => 'Minimum car year allowed for listing'],
        ];

        foreach ($settings as $setting) {
            PlatformSetting::firstOrCreate(['key' => $setting['key']], $setting);
        }
    }
}
