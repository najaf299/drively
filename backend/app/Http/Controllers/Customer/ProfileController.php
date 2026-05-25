<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

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
            'notification_settings' => ['sometimes', 'array'],
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
}
