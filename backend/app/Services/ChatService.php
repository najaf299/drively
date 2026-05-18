<?php

namespace App\Services;

use App\Events\MessageSent;
use App\Models\ChatMessage;
use App\Models\ChatThread;
use App\Models\User;

class ChatService
{
    public function getOrCreateThread(string $userOneId, string $userTwoId, ?string $bookingId = null): ChatThread
    {
        $participantOne = min($userOneId, $userTwoId);
        $participantTwo = max($userOneId, $userTwoId);

        return ChatThread::firstOrCreate(
            [
                'participant_one' => $participantOne,
                'participant_two' => $participantTwo,
            ],
            ['booking_id' => $bookingId]
        );
    }

    public function sendMessage(ChatThread $thread, User $sender, string $content, string $type = 'text', ?string $imageUrl = null): ChatMessage
    {
        $message = ChatMessage::create([
            'thread_id' => $thread->id,
            'sender_id' => $sender->id,
            'type' => $type,
            'content' => $content,
            'image_url' => $imageUrl,
        ]);

        $thread->touch();

        event(new MessageSent($message));

        return $message->load('sender:id,name,avatar_url');
    }

    public function markThreadAsRead(ChatThread $thread, string $userId): int
    {
        return $thread->messages()
            ->where('sender_id', '!=', $userId)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
    }
}
