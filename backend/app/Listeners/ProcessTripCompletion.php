<?php

namespace App\Listeners;

use App\Events\TripCompleted;

class ProcessTripCompletion
{
    public function handle(TripCompleted $event): void
    {
        // Calculate earnings
        // Create earning record
        // Update car/user stats
    }
}
