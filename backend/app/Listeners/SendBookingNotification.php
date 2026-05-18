<?php

namespace App\Listeners;

use App\Events\BookingCreated;
use App\Notifications\NewBookingNotification;

class SendBookingNotification
{
    public function handle(BookingCreated $event): void
    {
        $booking = $event->booking->load('car.host', 'customer');
        $host = $booking->car->host;

        $host->notify(new NewBookingNotification($booking));
    }
}
