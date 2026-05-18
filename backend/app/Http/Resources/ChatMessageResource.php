<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatMessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'thread_id' => $this->thread_id,
            'sender_id' => $this->sender_id,
            'content' => $this->content,
            'type' => $this->type,
            'image_url' => $this->image_url,
            'read_at' => $this->read_at?->toISOString(),
            'delivered_at' => $this->delivered_at?->toISOString(),
            'sender' => new UserSummaryResource($this->whenLoaded('sender')),
            'created_at' => $this->created_at,
        ];
    }
}
