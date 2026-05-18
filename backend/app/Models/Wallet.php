<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\DB;

class Wallet extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = ['user_id', 'balance', 'currency'];

    protected function casts(): array
    {
        return ['balance' => 'decimal:2'];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function transactions(): HasMany { return $this->hasMany(WalletTransaction::class); }

    public function credit(float $amount, string $description, ?string $bookingId = null): WalletTransaction
    {
        return DB::transaction(function () use ($amount, $description, $bookingId) {
            $this->increment('balance', $amount);
            $this->refresh();

            return $this->transactions()->create([
                'type' => 'credit',
                'amount' => $amount,
                'balance_after' => $this->balance,
                'description' => $description,
                'reference' => 'WLT-' . strtoupper(uniqid()),
                'booking_id' => $bookingId,
            ]);
        });
    }

    public function debit(float $amount, string $description, ?string $bookingId = null): WalletTransaction
    {
        if ($this->balance < $amount) {
            throw new \RuntimeException('Insufficient wallet balance.');
        }

        return DB::transaction(function () use ($amount, $description, $bookingId) {
            $this->decrement('balance', $amount);
            $this->refresh();

            return $this->transactions()->create([
                'type' => 'debit',
                'amount' => $amount,
                'balance_after' => $this->balance,
                'description' => $description,
                'reference' => 'WLT-' . strtoupper(uniqid()),
                'booking_id' => $bookingId,
            ]);
        });
    }
}
