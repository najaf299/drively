<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookingResource;
use App\Models\Booking;
use App\Services\BookingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    public function __construct(private BookingService $bookingService) {}

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
        ]);

        $validated['customer_id'] = $request->user()->id;
        $booking = $this->bookingService->createBooking($validated);

        return $this->success(new BookingResource($booking), 'Booking created', 201);
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
        $booking = $this->bookingService->cancelBooking($booking, $validated['reason']);
        return $this->success(new BookingResource($booking), 'Booking cancelled');
    }
}
