<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\Car;
use App\Models\Dispute;
use App\Models\Earning;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function index(): JsonResponse
    {
        // One conditional-aggregate query per table instead of ~22 separate
        // COUNT/SUM round trips. `CASE WHEN <bool>` / `CASE WHEN <col> = 'x'`
        // is portable across PostgreSQL (prod), MySQL, and SQLite (tests).
        // Users + KYC live on the same table, so they share one query.
        $users = User::selectRaw("
            COUNT(*) as total,
            COUNT(CASE WHEN role = 'host' THEN 1 END) as hosts,
            COUNT(CASE WHEN role = 'customer' THEN 1 END) as customers,
            COUNT(CASE WHEN is_suspended THEN 1 END) as suspended,
            COUNT(CASE WHEN kyc_status = 'pending' THEN 1 END) as kyc_pending,
            COUNT(CASE WHEN kyc_status = 'approved' THEN 1 END) as kyc_approved,
            COUNT(CASE WHEN kyc_status = 'rejected' THEN 1 END) as kyc_rejected
        ")->first();

        $cars = Car::selectRaw("
            COUNT(*) as total,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active,
            COUNT(CASE WHEN status = 'pending_approval' THEN 1 END) as pending_review
        ")->first();

        $bookings = Booking::selectRaw("
            COUNT(*) as total,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active,
            COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed
        ")->first();

        // Escalated dispute == status 'investigating' (see DisputeService::escalateDispute).
        $disputes = Dispute::selectRaw("
            COUNT(CASE WHEN status = 'open' THEN 1 END) as open,
            COUNT(CASE WHEN status = 'investigating' THEN 1 END) as escalated
        ")->first();

        $earnings = Earning::selectRaw('
            COALESCE(SUM(net_amount), 0) as total_earnings,
            COALESCE(SUM(platform_commission), 0) as total_commission
        ')->first();

        $revenueThisMonth = Booking::where('status', BookingStatus::Completed)
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->sum('total_amount');

        return $this->success([
            'users' => [
                'total' => (int) $users->total,
                'hosts' => (int) $users->hosts,
                'customers' => (int) $users->customers,
                'suspended' => (int) $users->suspended,
            ],
            'cars' => [
                'total' => (int) $cars->total,
                'active' => (int) $cars->active,
                'pending_review' => (int) $cars->pending_review,
            ],
            'bookings' => [
                'total' => (int) $bookings->total,
                'active' => (int) $bookings->active,
                'pending' => (int) $bookings->pending,
                'completed' => (int) $bookings->completed,
            ],
            'kyc' => [
                'pending' => (int) $users->kyc_pending,
                'approved' => (int) $users->kyc_approved,
                'rejected' => (int) $users->kyc_rejected,
            ],
            'disputes' => [
                'open' => (int) $disputes->open,
                'escalated' => (int) $disputes->escalated,
            ],
            'revenue' => [
                'this_month' => round((float) $revenueThisMonth, 2),
                'total_earnings' => round((float) $earnings->total_earnings, 2),
                'total_commission' => round((float) $earnings->total_commission, 2),
            ],
        ]);
    }
}
