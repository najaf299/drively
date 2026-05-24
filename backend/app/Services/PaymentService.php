<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Payment;

class PaymentService
{
    /** Whether real Stripe API calls are configured. */
    private function stripeConfigured(): bool
    {
        return !empty(config('services.stripe.secret'));
    }

    public function createPaymentIntent(Booking $booking, string $method = 'card'): array
    {
        // Demo mode: without Stripe keys, simulate a succeeded payment so the
        // booking flow is fully testable end-to-end. Wire STRIPE_SECRET in .env
        // to switch to real Stripe PaymentIntents.
        if (!$this->stripeConfigured()) {
            $reference = 'pi_demo_' . \Illuminate\Support\Str::random(24);

            $payment = Payment::create([
                'booking_id' => $booking->id,
                'method' => $method,
                'amount' => $booking->total_amount,
                'currency' => 'USD',
                'status' => 'succeeded',
                'paid_at' => now(),
                'stripe_payment_intent_id' => $reference,
            ]);

            $booking->update([
                'status' => 'confirmed',
                'confirmed_at' => now(),
            ]);

            return [
                'payment_id' => $payment->id,
                'client_secret' => $reference . '_secret_demo',
                'amount' => $booking->total_amount,
                'currency' => 'USD',
                'demo' => true,
            ];
        }

        $stripe = new \Stripe\StripeClient(config('services.stripe.secret'));

        $paymentIntent = $stripe->paymentIntents->create([
            'amount' => (int) ($booking->total_amount * 100),
            'currency' => 'usd',
            'metadata' => [
                'booking_id' => $booking->id,
                'booking_reference' => $booking->reference,
            ],
        ]);

        $payment = Payment::create([
            'booking_id' => $booking->id,
            'method' => $method,
            'amount' => $booking->total_amount,
            'currency' => 'USD',
            'status' => 'pending',
            'stripe_payment_intent_id' => $paymentIntent->id,
        ]);

        return [
            'payment_id' => $payment->id,
            'client_secret' => $paymentIntent->client_secret,
            'amount' => $booking->total_amount,
            'currency' => 'USD',
        ];
    }

    public function confirmPayment(string $paymentIntentId): Payment
    {
        $payment = Payment::where('stripe_payment_intent_id', $paymentIntentId)->firstOrFail();

        $payment->update([
            'status' => 'succeeded',
            'paid_at' => now(),
        ]);

        $payment->booking->update([
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);

        return $payment->fresh();
    }

    public function handleWebhook(array $event): void
    {
        $type = $event['type'] ?? '';
        $data = $event['data']['object'] ?? [];

        match ($type) {
            'payment_intent.succeeded' => $this->confirmPayment($data['id']),
            'payment_intent.payment_failed' => $this->failPayment($data['id']),
            default => null,
        };
    }

    public function failPayment(string $paymentIntentId): Payment
    {
        $payment = Payment::where('stripe_payment_intent_id', $paymentIntentId)->firstOrFail();
        $payment->update(['status' => 'failed']);
        return $payment->fresh();
    }

    public function refund(Payment $payment, float $amount, string $reason): Payment
    {
        // Demo mode: skip the live Stripe refund call when no keys are set.
        if ($this->stripeConfigured()) {
            $stripe = new \Stripe\StripeClient(config('services.stripe.secret'));

            $stripe->refunds->create([
                'payment_intent' => $payment->stripe_payment_intent_id,
                'amount' => (int) ($amount * 100),
                'reason' => 'requested_by_customer',
            ]);
        }

        $status = $amount >= $payment->amount ? 'refunded' : 'partially_refunded';
        $payment->update([
            'status' => $status,
            'refund_amount' => ($payment->refund_amount ?? 0) + $amount,
            'refund_reason' => $reason,
            'refunded_at' => now(),
        ]);

        return $payment->fresh();
    }
}
