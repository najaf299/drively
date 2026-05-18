<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['booking_id', 'method', 'amount', 'currency', 'status', 'stripe_payment_intent_id', 'stripe_charge_id', 'refund_amount', 'refund_reason', 'paid_at', 'refunded_at'];
    protected function casts(): array { return ['amount' => 'decimal:2', 'refund_amount' => 'decimal:2', 'paid_at' => 'datetime', 'refunded_at' => 'datetime']; }
    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
}
