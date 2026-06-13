<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\TripResource;
use App\Models\Booking;
use App\Models\Trip;
use App\Services\TripService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TripController extends Controller
{
    public function __construct(private TripService $tripService) {}

    public function show(Trip $trip): JsonResponse
    {
        $this->authorize('view', $trip);
        $trip->load(['booking.car.photos', 'booking.car.host:id,name,avatar_url,phone', 'inspections']);
        return $this->success(new TripResource($trip));
    }

    public function start(Request $request, Booking $booking): JsonResponse
    {
        $this->authorize('view', $booking);

        $validated = $request->validate([
            'mileage' => ['nullable', 'integer', 'min:0'],
            'fuel_level' => ['nullable', 'integer', 'min:0', 'max:100'],
            'zones' => ['nullable', 'array'],
            'photo_urls' => ['nullable', 'array'],
            'photo_urls.*' => ['url'],
            'notes' => ['nullable', 'string'],
        ]);

        $trip = $this->tripService->startTrip($booking, $validated);
        return $this->success(new TripResource($trip), 'Trip started', 201);
    }

    public function end(Request $request, Trip $trip): JsonResponse
    {
        $this->authorize('update', $trip);
        $validated = $request->validate([
            'mileage' => ['nullable', 'integer', 'min:0'],
            'fuel_level' => ['nullable', 'integer', 'min:0', 'max:100'],
            'zones' => ['nullable', 'array'],
            'photo_urls' => ['nullable', 'array'],
            'photo_urls.*' => ['url'],
            'notes' => ['nullable', 'string'],
            'damage_reported' => ['nullable', 'boolean'],
            'damage_description' => ['nullable', 'string'],
        ]);

        $trip = $this->tripService->endTrip($trip, $validated);
        return $this->success(new TripResource($trip), 'Trip ended');
    }

    public function updateLocation(Request $request, Trip $trip): JsonResponse
    {
        $this->authorize('update', $trip);
        $validated = $request->validate([
            'lat' => ['required', 'numeric'],
            'lng' => ['required', 'numeric'],
        ]);

        $trip = $this->tripService->updateLocation($trip, $validated['lat'], $validated['lng']);
        return $this->success(['lat' => $trip->last_known_lat, 'lng' => $trip->last_known_lng]);
    }

    public function extend(Request $request, Trip $trip): JsonResponse
    {
        $this->authorize('update', $trip);
        $validated = $request->validate([
            'extra_days' => ['required', 'integer', 'min:1', 'max:30'],
        ]);

        $trip = $this->tripService->extendTrip($trip, $validated['extra_days']);
        return $this->success(new TripResource($trip), 'Trip extended');
    }
}
