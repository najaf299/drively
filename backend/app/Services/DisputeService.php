<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Dispute;
use App\Models\User;

class DisputeService
{
    public function createDispute(User $reporter, Booking $booking, array $data): Dispute
    {
        return Dispute::create([
            'booking_id' => $booking->id,
            'reporter_id' => $reporter->id,
            'type' => $data['type'],
            'description' => $data['description'],
            'evidence_urls' => $data['evidence_urls'] ?? [],
            'status' => 'open',
        ]);
    }

    public function resolveDispute(Dispute $dispute, string $resolution, ?float $refundAmount = null, string $resolvedBy = null): Dispute
    {
        $dispute->update([
            'status' => 'resolved',
            'resolution' => $resolution,
            'refund_amount' => $refundAmount,
            'resolved_by' => $resolvedBy,
            'resolved_at' => now(),
        ]);

        return $dispute->fresh();
    }

    public function escalateDispute(Dispute $dispute): Dispute
    {
        $dispute->update(['status' => 'investigating']);
        return $dispute->fresh();
    }
}
