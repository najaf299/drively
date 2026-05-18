<?php

namespace App\Http\Controllers\Host;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookingResource;
use App\Models\Booking;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookingManagementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $bookings = Booking::whereHas('car', fn ($q) => $q->where('host_id', $request->user()->id))
            ->with(['car.photos', 'customer:id,name,avatar_url,average_rating'])
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->orderByDesc('created_at')
            ->paginate(20);

        return $this->success(BookingResource::collection($bookings));
    }

    public function approve(Booking $booking): JsonResponse
    {
        $booking->update(['status' => 'confirmed', 'confirmed_at' => now()]);
        return $this->success(new BookingResource($booking), 'Booking approved');
    }

    public function decline(Request $request, Booking $booking): JsonResponse
    {
        $validated = $request->validate(['reason' => ['required', 'string']]);
        $booking->update(['status' => 'declined', 'cancellation_reason' => $validated['reason']]);
        return $this->success(new BookingResource($booking), 'Booking declined');
    }
}
