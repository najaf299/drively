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

        // Total + active cars in a single query (conditional aggregate is
        // portable across MySQL and the SQLite test DB).
        $carCounts = $user->cars()
            ->selectRaw("COUNT(*) as total, COUNT(CASE WHEN status = 'active' THEN 1 END) as active")
            ->first();

        // Total + completed bookings in a single query (was two whereHas counts).
        $bookingCounts = Booking::whereHas('car', fn ($q) => $q->where('host_id', $hostId))
            ->selectRaw("COUNT(*) as total, COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed")
            ->first();

        return [
            'total_cars' => (int) $carCounts->total,
            'active_cars' => (int) $carCounts->active,
            'total_bookings' => (int) $bookingCounts->total,
            'completed_bookings' => (int) $bookingCounts->completed,
            'average_rating' => $user->average_rating,
            'total_trips' => $user->total_trips,
        ];
    }
}
