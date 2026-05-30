<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Settings endpoints — drive the in-app Settings screen end-to-end.
 *
 * The frontend reads `GET /settings` to populate every toggle/dropdown, and
 * writes a partial payload to `PUT /settings`. The merge here is shallow so
 * the client can update one section at a time without round-tripping the
 * full state.
 */
class SettingsController extends Controller
{
    /**
     * Default channel/privacy maps. Mirrored in the Flutter client so the UI
     * renders the same toggles for users with no saved preferences.
     */
    public static function defaultNotificationSettings(): array
    {
        return [
            'push' => [
                'bookings' => true,
                'messages' => true,
                'promotions' => true,
                'trip_updates' => true,
                'host_activity' => true,
            ],
            'email' => [
                'bookings' => true,
                'receipts' => true,
                'promotions' => false,
            ],
            'sms' => [
                'bookings' => false,
                'security' => true,
            ],
        ];
    }

    public static function defaultPrivacySettings(): array
    {
        return [
            'share_profile_with_hosts' => true,
            'analytics_opt_in' => true,
            'crash_reports_opt_in' => true,
            'marketing_opt_in' => false,
            'location_precision' => 'precise', // precise | approximate
        ];
    }

    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        return $this->success([
            'preferred_language' => $user->preferred_language ?? 'en',
            'preferred_currency' => $user->preferred_currency ?? 'USD',
            'preferred_units' => $user->preferred_units ?? 'km',
            'theme_mode' => $user->theme_mode ?? 'system',
            'notification_settings' => array_replace_recursive(
                self::defaultNotificationSettings(),
                (array) ($user->notification_settings ?? []),
            ),
            'privacy_settings' => array_replace_recursive(
                self::defaultPrivacySettings(),
                (array) ($user->privacy_settings ?? []),
            ),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'preferred_language' => ['sometimes', 'string', 'in:en,ar,fr,es,de'],
            'preferred_currency' => ['sometimes', 'string', 'size:3'],
            'preferred_units' => ['sometimes', 'in:km,mi'],
            'theme_mode' => ['sometimes', 'in:light,dark,system'],
            'notification_settings' => ['sometimes', 'array'],
            'privacy_settings' => ['sometimes', 'array'],
        ]);

        $user = $request->user();

        // Deep-merge JSON bags so the client can update a single channel
        // without nuking the others. Scalar prefs are overwritten directly.
        if (isset($validated['notification_settings'])) {
            $validated['notification_settings'] = array_replace_recursive(
                (array) ($user->notification_settings ?? []),
                $validated['notification_settings'],
            );
        }
        if (isset($validated['privacy_settings'])) {
            $validated['privacy_settings'] = array_replace_recursive(
                (array) ($user->privacy_settings ?? []),
                $validated['privacy_settings'],
            );
        }

        $user->update($validated);

        return $this->show($request);
    }

    /**
     * "Log out everywhere" — revokes every Sanctum token, including the one
     * making this request, so the client receives 401 on its next call and
     * routes the user back to the login screen.
     */
    public function logoutAllSessions(Request $request): JsonResponse
    {
        $request->user()->tokens()->delete();
        return $this->success(null, 'Signed out of every session.');
    }

    /**
     * Soft-deletes the signed-in user's account (GDPR-style erase). Requires
     * the current password to defend against stolen-token abuse, then revokes
     * every token so the device drops back to the login screen.
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        $request->validate([
            'password' => ['required_without:from_oauth', 'string'],
            'from_oauth' => ['sometimes', 'boolean'],
        ]);

        $user = $request->user();

        // Password check is skipped for accounts that have never set one
        // (pure Google/Apple sign-in). Those accounts pass `from_oauth=true`.
        $needsPassword = !$request->boolean('from_oauth') && $user->password;
        if ($needsPassword && !Hash::check($request->input('password'), $user->password)) {
            throw ValidationException::withMessages([
                'password' => ['Password is incorrect.'],
            ]);
        }

        $user->tokens()->delete();
        $user->delete(); // soft-delete via SoftDeletes trait

        return $this->success(null, 'Account deleted.');
    }
}
