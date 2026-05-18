<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Payment;

class PaymentService
{
    public function createPaymentIntent(Booking $booking): array
    {
        // Stripe integration placeholder
        return [
            'client_secret' => '',
            'payment_intent_id' => '',
            'amount' => $booking->total_amount,
            'currency' => 'usd',
        ];
    }

    public function confirmPayment(string $paymentIntentId): Payment
    {
        // Stripe webhook handler placeholder
        return new Payment();
    }

    public function refund(Payment $payment, float $amount, string $reason): Payment
    {
        $payment->update([
            'status' => $amount >= $payment->amount ? 'refunded' : 'partially_refunded',
            'refund_amount' => $amount,
            'refund_reason' => $reason,
            'refunded_at' => now(),
        ]);

        return $payment;
    }
}
