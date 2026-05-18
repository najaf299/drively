<?php

namespace App\Listeners;

use App\Events\KycSubmitted;
use Illuminate\Support\Facades\Log;

class NotifyAdminKycSubmission
{
    public function handle(KycSubmitted $event): void
    {
        Log::info('KYC document submitted for review', [
            'user_id' => $event->document->user_id,
            'document_type' => $event->document->document_type,
            'document_id' => $event->document->id,
        ]);
    }
}
