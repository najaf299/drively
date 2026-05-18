<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\ReviewResource;
use App\Models\Booking;
use App\Models\Car;
use App\Models\Review;
use App\Services\ReviewService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function __construct(private ReviewService $reviewService) {}

    public function store(Request $request, Booking $booking): JsonResponse
    {
        $validated = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'cleanliness_rating' => ['nullable', 'integer', 'min:1', 'max:5'],
            'communication_rating' => ['nullable', 'integer', 'min:1', 'max:5'],
            'accuracy_rating' => ['nullable', 'integer', 'min:1', 'max:5'],
            'pickup_rating' => ['nullable', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:1000'],
            'tags' => ['nullable', 'array'],
            'photo_urls' => ['nullable', 'array'],
            'photo_urls.*' => ['url'],
            'is_public' => ['nullable', 'boolean'],
        ]);

        if (!$this->reviewService->canReview($request->user(), $booking)) {
            return $this->error('You cannot review this booking.', 403);
        }

        $review = $this->reviewService->createReview($request->user(), $booking, $validated);
        return $this->success(new ReviewResource($review), 'Review submitted', 201);
    }

    public function carReviews(Car $car, Request $request): JsonResponse
    {
        $reviews = $car->reviews()
            ->with('reviewer:id,name,avatar_url')
            ->where('is_public', true)
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success(ReviewResource::collection($reviews));
    }

    public function myReviews(Request $request): JsonResponse
    {
        $reviews = Review::where('reviewer_id', $request->user()->id)
            ->with(['booking.car:id,make,model,year', 'reviewee:id,name,avatar_url'])
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success(ReviewResource::collection($reviews));
    }
}
