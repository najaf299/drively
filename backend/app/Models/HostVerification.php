<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HostVerification extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id', 'identity_status', 'bank_status', 'vehicle_status',
        'agreement_status', 'stripe_account_id', 'signature_url', 'completed_at',
    ];

    protected function casts(): array
    {
        return ['completed_at' => 'datetime'];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }

    public function isComplete(): bool
    {
        return $this->identity_status === 'approved'
            && $this->bank_status === 'approved'
            && $this->vehicle_status === 'approved'
            && $this->agreement_status === 'signed';
    }

    public function markComplete(): void
    {
        if ($this->isComplete() && !$this->completed_at) {
            $this->update(['completed_at' => now()]);
        }
    }

    public function updateStep(string $step, string $status): void
    {
        $this->update(["{$step}_status" => $status]);
        $this->refresh();
        $this->markComplete();
    }
}
