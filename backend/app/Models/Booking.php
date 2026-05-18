<?php

namespace App\Models;

use App\Enums\BookingStatus;
use App\Enums\BookingType;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class Booking extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'reference', 'car_id', 'customer_id', 'pickup_at', 'return_at',
        'daily_rate', 'total_days', 'subtotal', 'addons_total', 'service_fee',
        'tax', 'discount', 'total_amount', 'addons', 'pickup_address',
        'booking_type', 'status', 'cancellation_reason', 'confirmed_at',
        'cancelled_at', 'host_response_deadline',
    ];

    protected function casts(): array
    {
        return [
            'status' => BookingStatus::class,
            'booking_type' => BookingType::class,
            'pickup_at' => 'datetime',
            'return_at' => 'datetime',
            'confirmed_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'host_response_deadline' => 'datetime',
            'daily_rate' => 'decimal:2',
            'subtotal' => 'decimal:2',
            'addons_total' => 'decimal:2',
            'service_fee' => 'decimal:2',
            'tax' => 'decimal:2',
            'discount' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'addons' => 'array',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Booking $booking) {
            if (empty($booking->reference)) {
                $booking->reference = 'DRV-' . strtoupper(Str::random(8));
            }
        });
    }

    public function car(): BelongsTo { return $this->belongsTo(Car::class); }
    public function customer(): BelongsTo { return $this->belongsTo(User::class, 'customer_id'); }
    public function payment(): HasOne { return $this->hasOne(Payment::class); }
    public function trip(): HasOne { return $this->hasOne(Trip::class); }
    public function reviews(): HasMany { return $this->hasMany(Review::class); }
    public function disputes(): HasMany { return $this->hasMany(Dispute::class); }

    public function isPending(): bool { return $this->status === BookingStatus::Pending; }
    public function isConfirmed(): bool { return $this->status === BookingStatus::Confirmed; }
    public function isActive(): bool { return $this->status === BookingStatus::Active; }
    public function isCompleted(): bool { return $this->status === BookingStatus::Completed; }

    public function isCancellable(): bool
    {
        return in_array($this->status, [BookingStatus::Pending, BookingStatus::Confirmed]);
    }
}
