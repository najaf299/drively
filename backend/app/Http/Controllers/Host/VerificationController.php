<?php

namespace App\Http\Controllers\Host;

use App\Http\Controllers\Controller;
use App\Services\HostService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VerificationController extends Controller
{
    public function __construct(private HostService $hostService) {}

    public function status(Request $request): JsonResponse
    {
        $verification = $request->user()->hostVerification;
        if (!$verification) {
            return $this->success(['status' => 'not_started']);
        }

        return $this->success([
            'identity_status' => $verification->identity_status,
            'bank_status' => $verification->bank_status,
            'vehicle_status' => $verification->vehicle_status,
            'agreement_status' => $verification->agreement_status,
            'is_complete' => $verification->isComplete(),
            'completed_at' => $verification->completed_at,
        ]);
    }

    public function initiate(Request $request): JsonResponse
    {
        $verification = $this->hostService->initiateVerification($request->user());
        return $this->success($verification, 'Verification initiated', 201);
    }

    public function updateStep(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'step' => ['required', 'in:identity,bank,vehicle,agreement'],
            'data' => ['required', 'array'],
        ]);

        $verification = $request->user()->hostVerification;
        if (!$verification) {
            return $this->error('Please initiate verification first.', 400);
        }

        $verification->updateStep($validated['step'], 'submitted');
        return $this->success($verification->fresh(), 'Step updated');
    }

    public function stats(Request $request): JsonResponse
    {
        $stats = $this->hostService->getHostStats($request->user()->id);
        return $this->success($stats);
    }
}
