<?php

namespace App\Listeners;

use App\Events\BookingStatusChanged;

class NotifyBookingStatusChange
{
    public function handle(BookingStatusChanged $event): void
    {
        // Notify relevant parties about status change
    }
}
