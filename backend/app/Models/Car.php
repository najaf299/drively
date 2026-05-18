<?php

namespace App\Models;

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
        'suggested_price', 'description', 'features', 'lat', 'lng', 'address',
        'city', 'country', 'mileage_limit_per_day', 'excess_mileage_fee',
        'fuel_policy', 'smoking_allowed', 'pets_allowed', 'status', 'rejection_reason',
    ];

    protected function casts(): array
    {
        return [
            'features' => 'array', 'daily_price' => 'decimal:2',
            'lat' => 'decimal:7', 'lng' => 'decimal:7',
            'dynamic_pricing_enabled' => 'boolean', 'smoking_allowed' => 'boolean',
            'pets_allowed' => 'boolean', 'average_rating' => 'decimal:2',
        ];
    }

    public function host(): BelongsTo { return $this->belongsTo(User::class, 'host_id'); }
    public function photos(): HasMany { return $this->hasMany(CarPhoto::class)->orderBy('order'); }
    public function bookings(): HasMany { return $this->hasMany(Booking::class); }
    public function reviews(): HasMany { return $this->hasMany(Review::class); }
    public function availabilities(): HasMany { return $this->hasMany(CarAvailability::class); }
    public function scopeActive($query) { return $query->where('status', 'active'); }
}
