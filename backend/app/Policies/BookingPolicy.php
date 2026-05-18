<?php

namespace App\Policies;

use App\Models\Booking;
use App\Models\User;

class BookingPolicy
{
    public function view(User $user, Booking $booking): bool
    {
        return $user->id === $booking->customer_id
            || $user->id === $booking->car->host_id
            || $user->isAdmin();
    }

    public function cancel(User $user, Booking $booking): bool
    {
        return $user->id === $booking->customer_id && $booking->isCancellable();
    }

    public function review(User $user, Booking $booking): bool
    {
        return ($user->id === $booking->customer_id || $user->id === $booking->car->host_id)
            && $booking->isCompleted();
    }
}
