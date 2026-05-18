<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    public function sendPushNotification(User $user, string $title, string $body, array $data = []): void
    {
        $tokens = $user->deviceTokens()->where('is_active', true)->pluck('token');

        if ($tokens->isEmpty()) {
            return;
        }

        try {
            $messaging = app('firebase.messaging');
            foreach ($tokens as $token) {
                $message = \Kreait\Firebase\Messaging\CloudMessage::withTarget('token', $token)
                    ->withNotification([
                        'title' => $title,
                        'body' => $body,
                    ])
                    ->withData($data);

                $messaging->send($message);
            }
        } catch (\Exception $e) {
            Log::warning('Push notification failed', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    public function sendToTopic(string $topic, string $title, string $body, array $data = []): void
    {
        try {
            $messaging = app('firebase.messaging');
            $message = \Kreait\Firebase\Messaging\CloudMessage::withTarget('topic', $topic)
                ->withNotification([
                    'title' => $title,
                    'body' => $body,
                ])
                ->withData($data);

            $messaging->send($message);
        } catch (\Exception $e) {
            Log::warning('Topic notification failed', [
                'topic' => $topic,
                'error' => $e->getMessage(),
            ]);
        }
    }

    public function registerDeviceToken(User $user, string $token, string $platform): DeviceToken
    {
        return DeviceToken::updateOrCreate(
            ['user_id' => $user->id, 'token' => $token],
            ['platform' => $platform, 'is_active' => true],
        );
    }

    public function removeDeviceToken(string $token): void
    {
        DeviceToken::where('token', $token)->update(['is_active' => false]);
    }
}
