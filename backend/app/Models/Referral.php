<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Referral extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['referrer_id', 'referee_id', 'code', 'reward_amount', 'is_rewarded'];
    protected function casts(): array { return ['reward_amount' => 'decimal:2', 'is_rewarded' => 'boolean']; }
    public function referrer(): BelongsTo { return $this->belongsTo(User::class, 'referrer_id'); }
    public function referee(): BelongsTo { return $this->belongsTo(User::class, 'referee_id'); }
}
