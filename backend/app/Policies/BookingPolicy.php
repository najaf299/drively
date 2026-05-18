<?php

namespace App\Policies;

use App\Models\Booking;
use App\Models\User;

class BookingPolicy
{
    public function view(User $user, Booking $booking): bool
    {
        return $user->id === $booking->customer_id || $user->id === $booking->car->host_id || $user->isAdmin();
    }

    public function cancel(User $user, Booking $booking): bool
    {
        return $user->id === $booking->customer_id && in_array($booking->status, ['pending', 'confirmed']);
    }

    public function approve(User $user, Booking $booking): bool
    {
        return $user->id === $booking->car->host_id && $booking->status === 'pending';
    }
}
