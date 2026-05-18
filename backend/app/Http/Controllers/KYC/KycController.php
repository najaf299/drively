<?php

namespace App\Http\Controllers\KYC;

use App\Http\Controllers\Controller;
use App\Services\KycService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KycController extends Controller
{
    public function __construct(private KycService $kycService) {}

    public function status(Request $request): JsonResponse
    {
        return $this->success([
            'kyc_status' => $request->user()->kyc_status,
            'documents' => $request->user()->kycDocuments,
        ]);
    }

    public function submit(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'document_type' => ['required', 'in:drivers_license,government_id,insurance,registration'],
            'front_url' => ['required', 'string', 'url'],
            'back_url' => ['nullable', 'string', 'url'],
            'selfie_url' => ['nullable', 'string', 'url'],
        ]);

        $document = $this->kycService->submitDocument($request->user(), $validated);
        return $this->success($document, 'Document submitted', 201);
    }
}
