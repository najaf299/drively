<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\KycDocument;
use App\Services\KycService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KycManagementController extends Controller
{
    public function __construct(private KycService $kycService) {}

    public function pending(Request $request): JsonResponse
    {
        $documents = KycDocument::where('status', 'pending')
            ->with('user:id,name,email,phone')
            ->orderBy('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success($documents);
    }

    public function review(Request $request, KycDocument $document): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['required', 'in:approved,rejected'],
            'rejection_reason' => ['required_if:status,rejected', 'nullable', 'string', 'max:500'],
        ]);

        $document = $this->kycService->reviewDocument(
            $document,
            $validated['status'],
            $validated['rejection_reason'] ?? null,
            $request->user()->id,
        );

        return $this->success($document, "Document {$validated['status']}");
    }
}
