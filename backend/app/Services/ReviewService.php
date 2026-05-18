<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Review;
use App\Models\User;

class ReviewService
{
    public function createReview(User $reviewer, Booking $booking, array $data): Review
    {
        $isHost = $booking->car->host_id === $reviewer->id;

        $review = Review::create([
            'booking_id' => $booking->id,
            'reviewer_id' => $reviewer->id,
            'reviewee_id' => $isHost ? $booking->customer_id : $booking->car->host_id,
            'car_id' => $isHost ? null : $booking->car_id,
            'type' => $isHost ? 'host_to_renter' : 'renter_to_host',
            'rating' => $data['rating'],
            'cleanliness_rating' => $data['cleanliness_rating'] ?? null,
            'communication_rating' => $data['communication_rating'] ?? null,
            'accuracy_rating' => $data['accuracy_rating'] ?? null,
            'pickup_rating' => $data['pickup_rating'] ?? null,
            'comment' => $data['comment'] ?? null,
            'tags' => $data['tags'] ?? [],
            'photo_urls' => $data['photo_urls'] ?? [],
            'is_public' => $data['is_public'] ?? true,
        ]);

        return $review;
    }

    public function canReview(User $user, Booking $booking): bool
    {
        if ($booking->status->value !== 'completed') {
            return false;
        }

        $isCustomer = $booking->customer_id === $user->id;
        $isHost = $booking->car->host_id === $user->id;

        if (!$isCustomer && !$isHost) {
            return false;
        }

        return !Review::where('booking_id', $booking->id)
            ->where('reviewer_id', $user->id)
            ->exists();
    }
}
