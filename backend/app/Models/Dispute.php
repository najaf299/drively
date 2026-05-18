<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Dispute extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['booking_id', 'reporter_id', 'type', 'description', 'evidence_urls', 'status', 'resolution', 'refund_amount', 'resolved_by', 'resolved_at'];
    protected function casts(): array { return ['evidence_urls' => 'array', 'refund_amount' => 'decimal:2', 'resolved_at' => 'datetime']; }
    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
    public function reporter(): BelongsTo { return $this->belongsTo(User::class, 'reporter_id'); }
    public function resolver(): BelongsTo { return $this->belongsTo(User::class, 'resolved_by'); }
}
