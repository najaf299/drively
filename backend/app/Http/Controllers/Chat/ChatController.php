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
                'latestMessage.sender:id,name,avatar_url',
                'booking:id,reference,car_id',
                'booking.car:id,make,model,year',
            ])
            // Single correlated COUNT in the SELECT instead of one extra query
            // per thread (was an N+1 in the transform loop below).
            ->withCount(['messages as unread_count' => function ($q) use ($userId) {
                $q->where('sender_id', '!=', $userId)->whereNull('read_at');
            }])
            ->orderByDesc('updated_at')
            ->paginate(20);

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
            // Image messages carry the photo in image_url and may have no text.
            'content' => ['required_without:image_url', 'nullable', 'string', 'max:1000'],
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
            $validated['content'] ?? '', // content column is NOT NULL
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
