<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletTransaction extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['wallet_id', 'type', 'amount', 'balance_after', 'description', 'reference', 'booking_id'];
    protected function casts(): array { return ['amount' => 'decimal:2', 'balance_after' => 'decimal:2']; }
    public function wallet(): BelongsTo { return $this->belongsTo(Wallet::class); }
    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
}
