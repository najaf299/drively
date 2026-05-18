<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Earning extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['host_id', 'booking_id', 'gross_amount', 'platform_commission', 'insurance_fee', 'net_amount', 'status', 'stripe_transfer_id', 'paid_at'];
    protected function casts(): array { return ['gross_amount' => 'decimal:2', 'net_amount' => 'decimal:2', 'paid_at' => 'datetime']; }
    public function host(): BelongsTo { return $this->belongsTo(User::class, 'host_id'); }
    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
}
