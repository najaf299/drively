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
        $threads = ChatThread::where('participant_one', $request->user()->id)
            ->orWhere('participant_two', $request->user()->id)
            ->with(['participantOne:id,name,avatar_url', 'participantTwo:id,name,avatar_url', 'messages' => fn ($q) => $q->latest()->limit(1)])
            ->orderByDesc('updated_at')
            ->paginate(20);

        return $this->success($threads);
    }

    public function messages(ChatThread $thread, Request $request): JsonResponse
    {
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
        ]);

        $thread = $this->chatService->getOrCreateThread($request->user()->id, $validated['recipient_id'], $validated['booking_id'] ?? null);
        $message = $this->chatService->sendMessage($thread, $request->user(), $validated['content'], $validated['type'] ?? 'text');

        return $this->success($message, 'Message sent', 201);
    }
}
