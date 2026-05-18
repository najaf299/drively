<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureKycApproved
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user() && $request->user()->kyc_status !== 'approved') {
            return response()->json([
                'message' => 'KYC verification required.',
                'kyc_status' => $request->user()->kyc_status,
            ], 403);
        }

        return $next($request);
    }
}
