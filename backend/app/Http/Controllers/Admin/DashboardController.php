<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Enums\BookingStatus;
use App\Enums\KycStatus;
use App\Models\Booking;
use App\Models\Car;
use App\Models\Dispute;
use App\Models\Earning;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function index(): JsonResponse
    {
        return $this->success([
            'users' => [
                'total' => User::count(),
                'hosts' => User::where('role', 'host')->count(),
                'customers' => User::where('role', 'customer')->count(),
                'suspended' => User::where('is_suspended', true)->count(),
            ],
            'cars' => [
                'total' => Car::count(),
                'active' => Car::where('status', 'active')->count(),
                'pending_review' => Car::where('status', 'pending_review')->count(),
            ],
            'bookings' => [
                'total' => Booking::count(),
                'active' => Booking::where('status', BookingStatus::Active)->count(),
                'pending' => Booking::where('status', BookingStatus::Pending)->count(),
                'completed' => Booking::where('status', BookingStatus::Completed)->count(),
            ],
            'kyc' => [
                'pending' => User::where('kyc_status', KycStatus::Pending)->count(),
                'approved' => User::where('kyc_status', KycStatus::Approved)->count(),
                'rejected' => User::where('kyc_status', KycStatus::Rejected)->count(),
            ],
            'disputes' => [
                'open' => Dispute::where('status', 'open')->count(),
                'escalated' => Dispute::where('status', 'escalated')->count(),
            ],
            'revenue' => [
                'this_month' => Booking::where('status', BookingStatus::Completed)
                    ->whereMonth('created_at', now()->month)
                    ->whereYear('created_at', now()->year)
                    ->sum('total_amount'),
                'total_earnings' => Earning::sum('net_amount'),
                'total_commission' => Earning::sum('platform_commission'),
            ],
        ]);
    }
}
