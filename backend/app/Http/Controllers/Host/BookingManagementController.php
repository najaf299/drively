<?php

namespace App\Http\Controllers\Host;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookingResource;
use App\Models\Booking;
use App\Services\BookingService;
use App\Services\HostService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookingManagementController extends Controller
{
    public function __construct(
        private BookingService $bookingService,
        private HostService $hostService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $bookings = Booking::whereHas('car', fn ($q) => $q->where('host_id', $request->user()->id))
            ->with(['car.photos', 'customer:id,name,avatar_url,average_rating,total_trips'])
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->orderByDesc('created_at')
            ->paginate(20);

        return $this->success(BookingResource::collection($bookings));
    }

    public function approve(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->car->host_id !== $request->user()->id) {
            return $this->error('Unauthorized', 403);
        }

        try {
            $booking = $this->bookingService->approveBooking($booking);
            return $this->success(new BookingResource($booking), 'Booking approved');
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        }
    }

    public function decline(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->car->host_id !== $request->user()->id) {
            return $this->error('Unauthorized', 403);
        }

        $validated = $request->validate(['reason' => ['required', 'string', 'max:500']]);

        try {
            $booking = $this->bookingService->declineBooking($booking, $validated['reason']);
            return $this->success(new BookingResource($booking), 'Booking declined');
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        }
    }
}
