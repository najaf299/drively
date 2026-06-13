<?php

namespace App\Models;

use App\Enums\CarStatus;
use App\Enums\FuelPolicy;
use App\Enums\FuelType;
use App\Enums\Transmission;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Model;

class Car extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'host_id', 'make', 'model', 'year', 'trim', 'plate_number',
        'transmission', 'fuel_type', 'seats', 'doors', 'daily_price',
        'weekly_discount_pct', 'monthly_discount_pct', 'dynamic_pricing_enabled',
        'instant_booking', 'suggested_price', 'description', 'features', 'lat', 'lng', 'address',
        'city', 'country', 'mileage_limit_per_day', 'excess_mileage_fee',
        'fuel_policy', 'smoking_allowed', 'pets_allowed', 'status', 'rejection_reason',
    ];

    protected function casts(): array
    {
        return [
            'features' => 'array',
            'daily_price' => 'decimal:2',
            'suggested_price' => 'decimal:2',
            'weekly_discount_pct' => 'decimal:2',
            'monthly_discount_pct' => 'decimal:2',
            'excess_mileage_fee' => 'decimal:2',
            'lat' => 'decimal:7',
            'lng' => 'decimal:7',
            'transmission' => Transmission::class,
            'fuel_type' => FuelType::class,
            'fuel_policy' => FuelPolicy::class,
            'status' => CarStatus::class,
            'dynamic_pricing_enabled' => 'boolean',
            'instant_booking' => 'boolean',
            'smoking_allowed' => 'boolean',
            'pets_allowed' => 'boolean',
            'average_rating' => 'decimal:2',
        ];
    }

    public function host(): BelongsTo { return $this->belongsTo(User::class, 'host_id'); }
    public function photos(): HasMany { return $this->hasMany(CarPhoto::class)->orderBy('order'); }
    public function coverPhoto(): HasMany { return $this->hasMany(CarPhoto::class)->where('is_cover', true); }
    public function bookings(): HasMany { return $this->hasMany(Booking::class); }
    public function reviews(): HasMany { return $this->hasMany(Review::class); }
    public function availabilities(): HasMany { return $this->hasMany(CarAvailability::class); }
    public function favorites(): HasMany { return $this->hasMany(Favorite::class); }

    public function scopeActive($query) { return $query->where('status', CarStatus::Active); }
    public function scopeInCity($query, string $city) { return $query->where('city', $city); }
    public function scopeNearby($query, float $lat, float $lng, float $radiusKm = 25)
    {
        // Bounding-box prefilter so the (lat, lng) index can prune most rows
        // before the haversine runs on the survivors. ~111 km per degree of
        // latitude; longitude degrees shrink by cos(lat). Pad by 1° to stay safe
        // near the poles/antimeridian where the approximation is weakest.
        $latDelta = $radiusKm / 111.0;
        $lngDelta = $radiusKm / max(1.0, 111.0 * cos(deg2rad($lat)));

        $haversine = "(6371 * acos(cos(radians(?)) * cos(radians(lat)) * cos(radians(lng) - radians(?)) + sin(radians(?)) * sin(radians(lat))))";
        return $query
            ->whereBetween('lat', [$lat - $latDelta, $lat + $latDelta])
            ->whereBetween('lng', [$lng - $lngDelta, $lng + $lngDelta])
            ->selectRaw("*, {$haversine} AS distance", [$lat, $lng, $lat])
            ->having('distance', '<', $radiusKm)
            ->orderBy('distance');
    }

    public function isAvailableFor(string $startDate, string $endDate): bool
    {
        return !$this->bookings()
            ->whereIn('status', ['pending', 'confirmed', 'active'])
            ->where(function ($q) use ($startDate, $endDate) {
                $q->whereBetween('pickup_at', [$startDate, $endDate])
                    ->orWhereBetween('return_at', [$startDate, $endDate])
                    ->orWhere(function ($q2) use ($startDate, $endDate) {
                        $q2->where('pickup_at', '<=', $startDate)
                            ->where('return_at', '>=', $endDate);
                    });
            })->exists();
    }

    public function updateRating(): void
    {
        $avg = $this->reviews()->avg('rating');
        $count = $this->reviews()->count();
        $this->update(['average_rating' => $avg ?? 0, 'total_reviews' => $count]);
    }
}
