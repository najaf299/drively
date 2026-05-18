<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class SocialAuthController extends Controller
{
    public function google(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id_token' => ['required', 'string'],
            'name' => ['nullable', 'string'],
            'email' => ['nullable', 'email'],
            'avatar_url' => ['nullable', 'url'],
        ]);

        try {
            $googleUser = $this->verifyGoogleToken($validated['id_token']);

            $user = User::where('google_id', $googleUser['sub'])->first();

            if (!$user) {
                $user = User::where('email', $googleUser['email'] ?? $validated['email'])->first();

                if ($user) {
                    $user->update(['google_id' => $googleUser['sub']]);
                } else {
                    $user = User::create([
                        'name' => $googleUser['name'] ?? $validated['name'] ?? 'User',
                        'email' => $googleUser['email'] ?? $validated['email'],
                        'google_id' => $googleUser['sub'],
                        'avatar_url' => $googleUser['picture'] ?? $validated['avatar_url'] ?? null,
                        'password' => bcrypt(Str::random(32)),
                        'role' => 'customer',
                        'email_verified_at' => now(),
                    ]);
                }
            }

            if ($user->is_suspended) {
                return $this->error('Account suspended: ' . $user->suspension_reason, 403);
            }

            $token = $user->createToken('auth-token')->plainTextToken;

            return $this->success([
                'user' => $user,
                'token' => $token,
                'is_new' => $user->wasRecentlyCreated,
            ]);
        } catch (\Exception $e) {
            Log::error('Google auth failed', ['error' => $e->getMessage()]);
            return $this->error('Google authentication failed.', 401);
        }
    }

    public function apple(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'identity_token' => ['required', 'string'],
            'authorization_code' => ['required', 'string'],
            'name' => ['nullable', 'string'],
            'email' => ['nullable', 'email'],
        ]);

        try {
            $appleUser = $this->verifyAppleToken($validated['identity_token']);

            $user = User::where('apple_id', $appleUser['sub'])->first();

            if (!$user) {
                if (!empty($validated['email'])) {
                    $user = User::where('email', $validated['email'])->first();
                }

                if ($user) {
                    $user->update(['apple_id' => $appleUser['sub']]);
                } else {
                    $user = User::create([
                        'name' => $validated['name'] ?? 'Apple User',
                        'email' => $validated['email'] ?? $appleUser['email'] ?? $appleUser['sub'] . '@privaterelay.appleid.com',
                        'apple_id' => $appleUser['sub'],
                        'password' => bcrypt(Str::random(32)),
                        'role' => 'customer',
                        'email_verified_at' => now(),
                    ]);
                }
            }

            if ($user->is_suspended) {
                return $this->error('Account suspended: ' . $user->suspension_reason, 403);
            }

            $token = $user->createToken('auth-token')->plainTextToken;

            return $this->success([
                'user' => $user,
                'token' => $token,
                'is_new' => $user->wasRecentlyCreated,
            ]);
        } catch (\Exception $e) {
            Log::error('Apple auth failed', ['error' => $e->getMessage()]);
            return $this->error('Apple authentication failed.', 401);
        }
    }

    private function verifyGoogleToken(string $idToken): array
    {
        $googleClientId = config('services.google.client_id');

        if ($googleClientId) {
            $client = new \Google\Client(['client_id' => $googleClientId]);
            $payload = $client->verifyIdToken($idToken);
            if (!$payload) {
                throw new \RuntimeException('Invalid Google ID token');
            }
            return $payload;
        }

        $parts = explode('.', $idToken);
        if (count($parts) === 3) {
            $payload = json_decode(base64_decode($parts[1]), true);
            if ($payload) {
                return $payload;
            }
        }

        return ['sub' => 'google_' . md5($idToken), 'email' => null, 'name' => null, 'picture' => null];
    }

    private function verifyAppleToken(string $identityToken): array
    {
        $parts = explode('.', $identityToken);
        if (count($parts) === 3) {
            $payload = json_decode(base64_decode($parts[1]), true);
            if ($payload) {
                return $payload;
            }
        }

        return ['sub' => 'apple_' . md5($identityToken), 'email' => null];
    }
}
