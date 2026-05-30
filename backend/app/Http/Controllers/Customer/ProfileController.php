<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return $this->success($request->user()->load(['wallet', 'kycDocuments']));
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            // nullable so the app can clear the photo by sending null.
            'avatar_url' => ['sometimes', 'nullable', 'url'],
            'preferred_language' => ['sometimes', 'string', 'in:en,ar,fr,es,de'],
            'preferred_currency' => ['sometimes', 'string', 'size:3'],
            'preferred_units' => ['sometimes', 'in:km,mi'],
            'theme_mode' => ['sometimes', 'string', 'in:light,dark,system'],
            'notification_settings' => ['sometimes', 'array'],
            'privacy_settings' => ['sometimes', 'array'],
        ]);

        $request->user()->update($validated);
        return $this->success($request->user()->fresh());
    }

    /// Uploads a profile photo, stores it on the public disk and saves an
    /// absolute URL on the user. The URL is built from the request host (not
    /// APP_URL) so a phone hitting the Mac over the LAN gets a reachable link.
    public function uploadAvatar(Request $request): JsonResponse
    {
        $request->validate([
            'avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $user = $request->user();

        // Clean up the previous upload (only ones we stored under avatars/).
        if ($user->avatar_url && str_contains($user->avatar_url, '/storage/avatars/')) {
            $old = 'avatars/' . basename(parse_url($user->avatar_url, PHP_URL_PATH));
            Storage::disk('public')->delete($old);
        }

        $path = $request->file('avatar')->store('avatars', 'public');
        $url = $request->getSchemeAndHttpHost() . Storage::url($path);
        $user->update(['avatar_url' => $url]);

        return $this->success($user->fresh(), 'Photo updated');
    }

    /// Changes the signed-in user's password. Verifies the current password,
    /// updates to the new one and revokes every *other* session token (the
    /// current session is kept so the user stays signed in on this device).
    public function changePassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'confirmed', 'different:current_password'],
        ]);

        $user = $request->user();

        if (!Hash::check($validated['current_password'], $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Your current password is incorrect.'],
            ]);
        }

        $user->update(['password' => $validated['password']]);

        // Sign out every other device, keep the current session alive.
        $currentId = $user->currentAccessToken()->id;
        $user->tokens()->where('id', '!=', $currentId)->delete();

        return $this->success(null, 'Password updated.');
    }

    /// Unlinks a social provider (Google/Apple) from the account. Used by the
    /// "Linked accounts" screen — the client signs the user out afterwards.
    public function unlinkProvider(Request $request, string $provider): JsonResponse
    {
        $column = match ($provider) {
            'google' => 'google_id',
            'apple' => 'apple_id',
            default => null,
        };

        if ($column === null) {
            return $this->error('Unknown provider.', 422);
        }

        $user = $request->user();

        if (empty($user->{$column})) {
            return $this->error('That account is not linked.', 422);
        }

        $user->update([$column => null]);

        return $this->success(null, ucfirst($provider) . ' account unlinked.');
    }
}
