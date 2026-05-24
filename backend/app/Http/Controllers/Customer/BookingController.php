<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookingResource;
use App\Models\Booking;
use App\Models\Car;
use App\Services\BookingService;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    public function __construct(
        private BookingService $bookingService,
        private PaymentService $paymentService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $bookings = Booking::where('customer_id', $request->user()->id)
            ->with(['car.photos', 'car.host:id,name,avatar_url'])
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success(BookingResource::collection($bookings));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'car_id' => ['required', 'uuid', 'exists:cars,id'],
            'pickup_at' => ['required', 'date', 'after:now'],
            'return_at' => ['required', 'date', 'after:pickup_at'],
            'pickup_address' => ['required', 'string'],
            'addons' => ['nullable', 'array'],
            'promo_code' => ['nullable', 'string'],
            'booking_type' => ['nullable', 'in:instant,request'],
        ]);

        try {
            $booking = $this->bookingService->createBooking($request->user(), $validated);
            $booking->load(['car.photos', 'car.host:id,name,avatar_url']);

            return $this->success(new BookingResource($booking), 'Booking created', 201);
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        }
    }

    public function show(Booking $booking): JsonResponse
    {
        $this->authorize('view', $booking);
        $booking->load(['car.photos', 'car.host:id,name,avatar_url,phone', 'payment', 'trip', 'reviews']);
        return $this->success(new BookingResource($booking));
    }

    public function cancel(Request $request, Booking $booking): JsonResponse
    {
        $this->authorize('cancel', $booking);
        $validated = $request->validate(['reason' => ['required', 'string']]);

        try {
            $booking = $this->bookingService->cancelBooking($booking, $validated['reason']);
            return $this->success(new BookingResource($booking), 'Booking cancelled');
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        }
    }

    public function pricing(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'car_id' => ['required', 'uuid', 'exists:cars,id'],
            'pickup_at' => ['required', 'date', 'after:now'],
            'return_at' => ['required', 'date', 'after:pickup_at'],
            'promo_code' => ['nullable', 'string'],
            'addons' => ['nullable', 'array'],
        ]);

        $car = Car::findOrFail($validated['car_id']);
        $pricing = $this->bookingService->calculatePricing(
            $car,
            $validated['pickup_at'],
            $validated['return_at'],
            $validated['promo_code'] ?? null,
            $validated['addons'] ?? [],
        );

        return $this->success($pricing);
    }

    public function pay(Booking $booking): JsonResponse
    {
        $this->authorize('view', $booking);

        if (!$booking->isPending() && !$booking->isConfirmed()) {
            return $this->error('Payment not available for this booking status.', 422);
        }

        $paymentData = $this->paymentService->createPaymentIntent($booking);
        // The publishable key is public; the app needs it to present the sheet.
        $paymentData['publishable_key'] = config('services.stripe.key');

        return $this->success($paymentData);
    }

    /// Marks the booking's payment succeeded after the client confirms it with
    /// Stripe (used in dev where webhooks aren't wired). Idempotent.
    public function confirmPayment(Booking $booking): JsonResponse
    {
        $this->authorize('view', $booking);

        $payment = $booking->payment()->latest()->first();
        if ($payment && $payment->stripe_payment_intent_id) {
            $this->paymentService->confirmPayment($payment->stripe_payment_intent_id);
        } else {
            $booking->update(['status' => 'confirmed', 'confirmed_at' => now()]);
        }

        return $this->success(
            new BookingResource($booking->fresh()->load(['car.photos', 'payment'])),
            'Payment confirmed',
        );
    }
}
