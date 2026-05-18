<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['booking_id', 'reviewer_id', 'reviewee_id', 'car_id', 'type', 'rating', 'cleanliness_rating', 'communication_rating', 'accuracy_rating', 'pickup_rating', 'comment', 'tags', 'photo_urls', 'is_public'];
    protected function casts(): array { return ['tags' => 'array', 'photo_urls' => 'array', 'is_public' => 'boolean']; }
    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
    public function reviewer(): BelongsTo { return $this->belongsTo(User::class, 'reviewer_id'); }
    public function reviewee(): BelongsTo { return $this->belongsTo(User::class, 'reviewee_id'); }
    public function car(): BelongsTo { return $this->belongsTo(Car::class); }
}
