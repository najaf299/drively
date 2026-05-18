<?php

namespace App\Services;

use App\Models\Earning;
use App\Models\HostVerification;
use App\Models\User;

class HostService
{
    public function initiateVerification(User $user): HostVerification
    {
        return HostVerification::firstOrCreate(
            ['user_id' => $user->id],
            [
                'identity_status' => 'pending',
                'bank_status' => 'pending',
                'vehicle_status' => 'pending',
                'agreement_status' => 'pending',
            ]
        );
    }

    public function calculateEarnings(string $hostId, string $period = 'month'): array
    {
        $query = Earning::where('host_id', $hostId);

        if ($period === 'month') {
            $query->whereMonth('created_at', now()->month);
        } elseif ($period === 'year') {
            $query->whereYear('created_at', now()->year);
        }

        return [
            'total_gross' => $query->sum('gross_amount'),
            'total_commission' => $query->sum('platform_commission'),
            'total_net' => $query->sum('net_amount'),
            'total_bookings' => $query->count(),
        ];
    }
}
