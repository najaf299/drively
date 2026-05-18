<?php

namespace App\Services;

use App\Enums\KycStatus;
use App\Models\KycDocument;
use App\Models\User;
use App\Events\KycSubmitted;

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

        $user->update(['kyc_status' => KycStatus::Pending]);

        event(new KycSubmitted($document));

        return $document;
    }

    public function reviewDocument(KycDocument $document, string $status, ?string $reason = null, ?string $reviewerId = null): KycDocument
    {
        $document->update([
            'status' => $status,
            'rejection_reason' => $reason,
            'reviewed_at' => now(),
            'reviewed_by' => $reviewerId,
        ]);

        $kycStatus = match ($status) {
            'approved' => KycStatus::Approved,
            'rejected' => KycStatus::Rejected,
            default => KycStatus::Pending,
        };

        $document->user->update(['kyc_status' => $kycStatus]);

        return $document->fresh();
    }

    public function getUserDocuments(User $user): array
    {
        return [
            'kyc_status' => $user->kyc_status,
            'documents' => $user->kycDocuments()->orderByDesc('created_at')->get(),
        ];
    }
}
