<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChatThread extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['booking_id', 'participant_one', 'participant_two', 'is_archived'];
    protected function casts(): array { return ['is_archived' => 'boolean']; }
    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
    public function participantOne(): BelongsTo { return $this->belongsTo(User::class, 'participant_one'); }
    public function participantTwo(): BelongsTo { return $this->belongsTo(User::class, 'participant_two'); }
    public function messages(): HasMany { return $this->hasMany(ChatMessage::class, 'thread_id'); }
}
