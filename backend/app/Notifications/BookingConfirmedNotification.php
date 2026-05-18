<?php

namespace App\Notifications;

use App\Models\Booking;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class BookingConfirmedNotification extends Notification
{
    use Queueable;

    public function __construct(private Booking $booking) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type' => 'booking_confirmed',
            'booking_id' => $this->booking->id,
            'reference' => $this->booking->reference,
            'car' => $this->booking->car->make . ' ' . $this->booking->car->model,
            'pickup_at' => $this->booking->pickup_at->toISOString(),
            'message' => "Your booking {$this->booking->reference} has been confirmed!",
        ];
    }
}
