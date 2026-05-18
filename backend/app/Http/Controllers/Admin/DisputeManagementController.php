<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\DisputeResource;
use App\Models\Dispute;
use App\Services\DisputeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DisputeManagementController extends Controller
{
    public function __construct(private DisputeService $disputeService) {}

    public function index(Request $request): JsonResponse
    {
        $disputes = Dispute::query()
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->with(['booking.car:id,make,model', 'reporter:id,name,email'])
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success(DisputeResource::collection($disputes));
    }

    public function resolve(Request $request, Dispute $dispute): JsonResponse
    {
        $validated = $request->validate([
            'resolution' => ['required', 'string', 'max:2000'],
            'refund_amount' => ['nullable', 'numeric', 'min:0'],
        ]);

        $dispute = $this->disputeService->resolveDispute(
            $dispute,
            $validated['resolution'],
            $validated['refund_amount'] ?? null,
            $request->user()->id,
        );

        return $this->success(new DisputeResource($dispute), 'Dispute resolved');
    }

    public function escalate(Dispute $dispute): JsonResponse
    {
        $dispute = $this->disputeService->escalateDispute($dispute);
        return $this->success(new DisputeResource($dispute), 'Dispute escalated');
    }
}
