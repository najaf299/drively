<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureHostVerified
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || $user->role !== 'host') {
            return response()->json(['message' => 'Host access required.'], 403);
        }

        $verification = $user->hostVerification;
        if (!$verification || !$verification->completed_at) {
            return response()->json([
                'message' => 'Host verification incomplete.',
                'verification_status' => [
                    'identity' => $verification?->identity_status ?? 'pending',
                    'bank' => $verification?->bank_status ?? 'pending',
                    'vehicle' => $verification?->vehicle_status ?? 'pending',
                    'agreement' => $verification?->agreement_status ?? 'pending',
                ],
            ], 403);
        }

        return $next($request);
    }
}
