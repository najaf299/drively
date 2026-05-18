<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class KycDocument extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['user_id', 'document_type', 'front_url', 'back_url', 'selfie_url', 'status', 'rejection_reason', 'reviewed_at', 'reviewed_by'];
    protected function casts(): array { return ['reviewed_at' => 'datetime']; }
    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function reviewer(): BelongsTo { return $this->belongsTo(User::class, 'reviewed_by'); }
}
