<?php

namespace App\Services;

use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;

class WalletService
{
    public function getOrCreateWallet(User $user): Wallet
    {
        return $user->wallet ?? Wallet::create([
            'user_id' => $user->id,
            'balance' => 0,
            'currency' => 'USD',
        ]);
    }

    public function credit(Wallet $wallet, float $amount, string $description, ?string $bookingId = null): WalletTransaction
    {
        return $wallet->credit($amount, $description, $bookingId);
    }

    public function debit(Wallet $wallet, float $amount, string $description, ?string $bookingId = null): WalletTransaction
    {
        return $wallet->debit($amount, $description, $bookingId);
    }

    public function getTransactionHistory(Wallet $wallet, ?string $type = null, int $perPage = 20)
    {
        $query = $wallet->transactions()->orderByDesc('created_at');

        if ($type) {
            $query->where('type', $type);
        }

        return $query->paginate($perPage);
    }
}
