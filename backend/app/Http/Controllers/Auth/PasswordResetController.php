<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class PasswordResetController extends Controller
{
    /**
     * Step 1 — request a reset code.
     *
     * Generates a 6-digit code, caches it for 15 minutes and (in a real
     * deployment) emails it. To avoid leaking which emails exist we always
     * return success. When the app is in debug mode the code is also returned
     * in the payload so the flow is testable without an email provider.
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        // Only generate/store a code for real accounts, but respond the same
        // either way so the endpoint can't be used to enumerate users.
        if ($user) {
            $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            Cache::put("pwreset:{$validated['email']}", $code, now()->addMinutes(15));
            Log::info("Password reset code for {$validated['email']}: {$code}");

            // TODO(prod): dispatch a Mailable here instead of logging.

            return $this->success(
                config('app.debug') ? ['dev_code' => $code] : null,
                'If an account exists for that email, a reset code has been sent.'
            );
        }

        return $this->success(
            null,
            'If an account exists for that email, a reset code has been sent.'
        );
    }

    /**
     * Step 2 — verify the code and set a new password.
     *
     * On success all existing tokens are revoked so any other sessions are
     * signed out, then a fresh token is issued so the user lands signed in.
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'string', 'size:6'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $cached = Cache::get("pwreset:{$validated['email']}");

        if (!$cached || $cached !== $validated['code']) {
            return $this->error('Invalid or expired reset code.', 422);
        }

        $user = User::where('email', $validated['email'])->first();

        if (!$user) {
            return $this->error('Account not found.', 404);
        }

        $user->update(['password' => $validated['password']]);
        Cache::forget("pwreset:{$validated['email']}");

        // Revoke every existing token, then issue a fresh one.
        $user->tokens()->delete();
        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->success([
            'user' => $user,
            'token' => $token,
        ], 'Password reset successfully.');
    }
}
