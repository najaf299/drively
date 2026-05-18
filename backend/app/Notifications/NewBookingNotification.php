<?php

namespace App\Notifications;

use App\Models\Booking;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewBookingNotification extends Notification
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
            'type' => 'new_booking',
            'booking_id' => $this->booking->id,
            'reference' => $this->booking->reference,
            'customer_name' => $this->booking->customer->name,
            'car' => $this->booking->car->make . ' ' . $this->booking->car->model,
            'pickup_at' => $this->booking->pickup_at->toISOString(),
            'return_at' => $this->booking->return_at->toISOString(),
            'total_amount' => $this->booking->total_amount,
            'message' => "New booking request from {$this->booking->customer->name}",
        ];
    }
}
