<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ChatThread extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = ['booking_id', 'participant_one', 'participant_two', 'is_archived'];

    protected function casts(): array
    {
        return ['is_archived' => 'boolean'];
    }

    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
    public function participantOne(): BelongsTo { return $this->belongsTo(User::class, 'participant_one'); }
    public function participantTwo(): BelongsTo { return $this->belongsTo(User::class, 'participant_two'); }
    public function messages(): HasMany { return $this->hasMany(ChatMessage::class, 'thread_id'); }
    public function latestMessage(): HasOne { return $this->hasOne(ChatMessage::class, 'thread_id')->latestOfMany(); }

    public function hasParticipant(string $userId): bool
    {
        return $this->participant_one === $userId || $this->participant_two === $userId;
    }

    public function otherParticipant(string $userId): string
    {
        return $this->participant_one === $userId ? $this->participant_two : $this->participant_one;
    }

    public function unreadCountFor(string $userId): int
    {
        return $this->messages()
            ->where('sender_id', '!=', $userId)
            ->whereNull('read_at')
            ->count();
    }
}
