<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatThreadResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $other = $this->otherParticipant($user->id);

        return [
            'id' => $this->id,
            'other_participant' => $other ? new UserSummaryResource($other) : null,
            'booking_id' => $this->booking_id,
            'unread_count' => $this->unreadCountFor($user->id),
            'latest_message' => $this->whenLoaded('latestMessage', fn () => new ChatMessageResource($this->latestMessage)),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
