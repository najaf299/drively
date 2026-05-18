<?php

namespace App\Services;

use App\Enums\Role;
use App\Models\Earning;
use App\Models\Booking;
use App\Models\HostVerification;
use App\Models\User;
use Carbon\Carbon;

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

    public function updateVerificationStep(HostVerification $verification, string $step, string $status): HostVerification
    {
        $verification->updateStep($step, $status);
        return $verification->fresh();
    }

    public function calculateEarnings(string $hostId, string $period = 'month'): array
    {
        $query = Earning::where('host_id', $hostId);

        match ($period) {
            'week' => $query->where('created_at', '>=', now()->subWeek()),
            'month' => $query->whereMonth('created_at', now()->month)->whereYear('created_at', now()->year),
            'year' => $query->whereYear('created_at', now()->year),
            'all' => null,
            default => $query->whereMonth('created_at', now()->month),
        };

        $earnings = $query->get();

        return [
            'total_gross' => round($earnings->sum('gross_amount'), 2),
            'total_commission' => round($earnings->sum('platform_commission'), 2),
            'total_insurance' => round($earnings->sum('insurance_fee'), 2),
            'total_net' => round($earnings->sum('net_amount'), 2),
            'total_bookings' => $earnings->count(),
            'period' => $period,
        ];
    }

    public function createEarning(Booking $booking): Earning
    {
        $grossAmount = (float) $booking->total_amount;
        $commission = round($grossAmount * 0.15, 2);
        $insurance = round($grossAmount * 0.05, 2);
        $netAmount = round($grossAmount - $commission - $insurance, 2);

        return Earning::create([
            'host_id' => $booking->car->host_id,
            'booking_id' => $booking->id,
            'gross_amount' => $grossAmount,
            'platform_commission' => $commission,
            'insurance_fee' => $insurance,
            'net_amount' => $netAmount,
            'status' => 'pending',
        ]);
    }

    public function getHostStats(string $hostId): array
    {
        $user = User::findOrFail($hostId);
        $cars = $user->cars()->count();
        $activeCars = $user->cars()->where('status', 'active')->count();
        $totalBookings = Booking::whereHas('car', fn ($q) => $q->where('host_id', $hostId))->count();
        $completedBookings = Booking::whereHas('car', fn ($q) => $q->where('host_id', $hostId))
            ->where('status', 'completed')->count();

        return [
            'total_cars' => $cars,
            'active_cars' => $activeCars,
            'total_bookings' => $totalBookings,
            'completed_bookings' => $completedBookings,
            'average_rating' => $user->average_rating,
            'total_trips' => $user->total_trips,
        ];
    }
}
