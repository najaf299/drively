<?php

namespace App\Http\Middleware;

use App\Enums\KycStatus;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureKycApproved
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || $user->kyc_status !== KycStatus::Approved) {
            return response()->json([
                'message' => 'KYC verification required.',
                'kyc_status' => $user?->kyc_status?->value ?? 'none',
            ], 403);
        }

        return $next($request);
    }
}
