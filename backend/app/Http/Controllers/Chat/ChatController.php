<?php

namespace App\Http\Controllers\Chat;

use App\Http\Controllers\Controller;
use App\Models\ChatThread;
use App\Services\ChatService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function __construct(private ChatService $chatService) {}

    public function threads(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $threads = ChatThread::where(function ($q) use ($userId) {
                $q->where('participant_one', $userId)
                    ->orWhere('participant_two', $userId);
            })
            ->with([
                'participantOne:id,name,avatar_url',
                'participantTwo:id,name,avatar_url',
                'latestMessage',
                'booking:id,reference,car_id',
                'booking.car:id,make,model,year',
            ])
            ->orderByDesc('updated_at')
            ->paginate(20);

        $threads->getCollection()->transform(function ($thread) use ($userId) {
            $thread->unread_count = $thread->unreadCountFor($userId);
            return $thread;
        });

        return $this->success($threads);
    }

    public function messages(ChatThread $thread, Request $request): JsonResponse
    {
        if (!$thread->hasParticipant($request->user()->id)) {
            return $this->error('Unauthorized', 403);
        }

        $messages = $thread->messages()
            ->with('sender:id,name,avatar_url')
            ->orderByDesc('created_at')
            ->paginate(50);

        return $this->success($messages);
    }

    public function send(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'recipient_id' => ['required', 'uuid', 'exists:users,id'],
            'booking_id' => ['nullable', 'uuid', 'exists:bookings,id'],
            'content' => ['required', 'string', 'max:1000'],
            'type' => ['sometimes', 'in:text,image'],
            'image_url' => ['nullable', 'url'],
        ]);

        $thread = $this->chatService->getOrCreateThread(
            $request->user()->id,
            $validated['recipient_id'],
            $validated['booking_id'] ?? null,
        );

        $message = $this->chatService->sendMessage(
            $thread,
            $request->user(),
            $validated['content'],
            $validated['type'] ?? 'text',
            $validated['image_url'] ?? null,
        );

        return $this->success($message, 'Message sent', 201);
    }

    public function markAsRead(ChatThread $thread, Request $request): JsonResponse
    {
        if (!$thread->hasParticipant($request->user()->id)) {
            return $this->error('Unauthorized', 403);
        }

        $count = $this->chatService->markThreadAsRead($thread, $request->user()->id);
        return $this->success(['marked_read' => $count]);
    }
}
