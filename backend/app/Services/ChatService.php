<?php

namespace App\Services;

use App\Models\ChatThread;
use App\Models\ChatMessage;
use App\Models\User;

class ChatService
{
    public function getOrCreateThread(string $userOneId, string $userTwoId, ?string $bookingId = null): ChatThread
    {
        return ChatThread::firstOrCreate(
            [
                'participant_one' => min($userOneId, $userTwoId),
                'participant_two' => max($userOneId, $userTwoId),
                'booking_id' => $bookingId,
            ]
        );
    }

    public function sendMessage(ChatThread $thread, User $sender, string $content, string $type = 'text'): ChatMessage
    {
        return ChatMessage::create([
            'thread_id' => $thread->id,
            'sender_id' => $sender->id,
            'type' => $type,
            'content' => $content,
        ]);
    }
}
