<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Booking extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'reference', 'car_id', 'customer_id', 'pickup_at', 'return_at',
        'daily_rate', 'total_days', 'subtotal', 'addons_total', 'service_fee',
        'tax', 'discount', 'total_amount', 'addons', 'pickup_address',
        'booking_type', 'status', 'cancellation_reason', 'promo_code_id',
        'confirmed_at', 'cancelled_at', 'host_response_deadline',
    ];

    protected function casts(): array
    {
        return [
            'pickup_at' => 'datetime', 'return_at' => 'datetime',
            'confirmed_at' => 'datetime', 'cancelled_at' => 'datetime',
            'host_response_deadline' => 'datetime', 'addons' => 'array',
            'daily_rate' => 'decimal:2', 'total_amount' => 'decimal:2',
        ];
    }

    public function car(): BelongsTo { return $this->belongsTo(Car::class); }
    public function customer(): BelongsTo { return $this->belongsTo(User::class, 'customer_id'); }
    public function payment(): HasOne { return $this->hasOne(Payment::class); }
    public function trip(): HasOne { return $this->hasOne(Trip::class); }
    public function promoCode(): BelongsTo { return $this->belongsTo(PromoCode::class); }
    public function reviews(): HasMany { return $this->hasMany(Review::class); }
    public function chatThread(): HasOne { return $this->hasOne(ChatThread::class); }

    public static function generateReference(): string
    {
        return 'DRV-' . random_int(10000, 99999);
    }
}
