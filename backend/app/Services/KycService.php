<?php

namespace App\Services;

use App\Models\KycDocument;
use App\Models\User;

class KycService
{
    public function submitDocument(User $user, array $data): KycDocument
    {
        $document = KycDocument::create([
            'user_id' => $user->id,
            'document_type' => $data['document_type'],
            'front_url' => $data['front_url'],
            'back_url' => $data['back_url'] ?? null,
            'selfie_url' => $data['selfie_url'] ?? null,
            'status' => 'pending',
        ]);

        $user->update(['kyc_status' => 'pending']);

        return $document;
    }

    public function reviewDocument(KycDocument $document, string $status, ?string $reason = null): KycDocument
    {
        $document->update([
            'status' => $status,
            'rejection_reason' => $reason,
            'reviewed_at' => now(),
        ]);

        if ($status === 'approved') {
            $document->user->update(['kyc_status' => 'approved']);
        } elseif ($status === 'rejected') {
            $document->user->update(['kyc_status' => 'rejected']);
        }

        return $document;
    }
}
