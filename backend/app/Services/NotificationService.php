<?php

namespace App\Services;

use App\Models\User;

class NotificationService
{
    public function sendPushNotification(User $user, string $title, string $body, array $data = []): void
    {
        $tokens = $user->deviceTokens()->where('is_active', true)->pluck('token');

        if ($tokens->isEmpty()) {
            return;
        }

        // Firebase Cloud Messaging integration placeholder
    }

    public function sendToTopic(string $topic, string $title, string $body, array $data = []): void
    {
        // Firebase topic messaging placeholder
    }
}
