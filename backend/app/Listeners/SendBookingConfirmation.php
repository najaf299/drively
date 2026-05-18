<?php

namespace App\Listeners;

use App\Events\BookingCreated;

class SendBookingConfirmation
{
    public function handle(BookingCreated $event): void
    {
        // Send notification to host about new booking
        // Send confirmation to customer
    }
}
