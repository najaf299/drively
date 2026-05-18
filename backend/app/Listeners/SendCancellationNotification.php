<?php

namespace App\Listeners;

use App\Events\BookingCancelled;
use App\Notifications\BookingCancelledNotification;

class SendCancellationNotification
{
    public function handle(BookingCancelled $event): void
    {
        $booking = $event->booking->load('car.host', 'customer');
        $host = $booking->car->host;

        $host->notify(new BookingCancelledNotification($booking));
    }
}
