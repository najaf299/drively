<?php

namespace App\Http\Controllers\Webhook;

use App\Http\Controllers\Controller;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class StripeWebhookController extends Controller
{
    public function __construct(private PaymentService $paymentService) {}

    public function handle(Request $request): JsonResponse
    {
        $payload = $request->all();
        $sigHeader = $request->header('Stripe-Signature');
        $webhookSecret = config('services.stripe.webhook_secret');

        if ($webhookSecret && $sigHeader) {
            try {
                \Stripe\Webhook::constructEvent(
                    $request->getContent(),
                    $sigHeader,
                    $webhookSecret,
                );
            } catch (\Exception $e) {
                Log::error('Stripe webhook signature verification failed', ['error' => $e->getMessage()]);
                return response()->json(['error' => 'Invalid signature'], 400);
            }
        }

        try {
            $this->paymentService->handleWebhook($payload);
        } catch (\Exception $e) {
            Log::error('Stripe webhook processing failed', [
                'type' => $payload['type'] ?? 'unknown',
                'error' => $e->getMessage(),
            ]);
        }

        return response()->json(['status' => 'ok']);
    }
}
