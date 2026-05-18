<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function __construct(private WalletService $walletService) {}

    public function show(Request $request): JsonResponse
    {
        $wallet = $this->walletService->getOrCreateWallet($request->user());
        return $this->success([
            'id' => $wallet->id,
            'balance' => $wallet->balance,
            'currency' => $wallet->currency,
        ]);
    }

    public function transactions(Request $request): JsonResponse
    {
        $wallet = $this->walletService->getOrCreateWallet($request->user());
        $transactions = $this->walletService->getTransactionHistory(
            $wallet,
            $request->type,
            $request->per_page ?? 20,
        );

        return $this->success($transactions);
    }

    public function topUp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'min:5', 'max:10000'],
        ]);

        $wallet = $this->walletService->getOrCreateWallet($request->user());
        $transaction = $this->walletService->credit($wallet, $validated['amount'], 'Wallet top-up');

        return $this->success([
            'transaction' => $transaction,
            'new_balance' => $wallet->fresh()->balance,
        ], 'Wallet topped up', 201);
    }
}
