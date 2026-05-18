<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Car;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function index(): JsonResponse
    {
        return $this->success([
            'total_users' => User::count(),
            'total_cars' => Car::count(),
            'total_bookings' => Booking::count(),
            'active_bookings' => Booking::where('status', 'active')->count(),
            'pending_kyc' => User::where('kyc_status', 'pending')->count(),
            'revenue_this_month' => Booking::where('status', 'completed')
                ->whereMonth('created_at', now()->month)
                ->sum('total_amount'),
        ]);
    }
}
