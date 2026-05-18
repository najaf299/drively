<?php

namespace App\Jobs;

use App\Enums\BookingStatus;
use App\Models\Booking;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessBookingExpiry implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function handle(): void
    {
        Booking::where('status', BookingStatus::Pending)
            ->where('host_response_deadline', '<', now())
            ->each(function (Booking $booking) {
                $booking->update([
                    'status' => BookingStatus::Expired,
                    'cancellation_reason' => 'Host did not respond within the deadline.',
                    'cancelled_at' => now(),
                ]);
            });
    }
}
