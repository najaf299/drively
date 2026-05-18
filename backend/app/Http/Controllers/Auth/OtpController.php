<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class OtpController extends Controller
{
    public function sendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
        ]);

        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        Cache::put("otp:{$validated['phone']}", $otp, now()->addMinutes(5));

        Log::info("OTP for {$validated['phone']}: {$otp}");

        return $this->success(message: 'OTP sent successfully');
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
            'code' => ['required', 'string', 'size:6'],
        ]);

        $cachedOtp = Cache::get("otp:{$validated['phone']}");

        if (!$cachedOtp || $cachedOtp !== $validated['code']) {
            return $this->error('Invalid or expired OTP.', 422);
        }

        Cache::forget("otp:{$validated['phone']}");

        $user = User::where('phone', $validated['phone'])->first();

        if ($user) {
            $user->update(['phone_verified_at' => now()]);
            $token = $user->createToken('auth-token')->plainTextToken;

            return $this->success([
                'user' => $user,
                'token' => $token,
                'is_new' => false,
            ], 'Phone verified');
        }

        return $this->success([
            'phone_verified' => true,
            'is_new' => true,
        ], 'OTP verified. Please complete registration.');
    }
}
