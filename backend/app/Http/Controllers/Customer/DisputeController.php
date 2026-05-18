<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\DisputeResource;
use App\Models\Booking;
use App\Models\Dispute;
use App\Services\DisputeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DisputeController extends Controller
{
    public function __construct(private DisputeService $disputeService) {}

    public function index(Request $request): JsonResponse
    {
        $disputes = Dispute::where('reporter_id', $request->user()->id)
            ->with(['booking.car:id,make,model,year'])
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success(DisputeResource::collection($disputes));
    }

    public function store(Request $request, Booking $booking): JsonResponse
    {
        $validated = $request->validate([
            'type' => ['required', 'in:damage,late_return,no_show,fraud,other'],
            'description' => ['required', 'string', 'max:2000'],
            'evidence_urls' => ['nullable', 'array'],
            'evidence_urls.*' => ['url'],
        ]);

        $dispute = $this->disputeService->createDispute($request->user(), $booking, $validated);
        return $this->success(new DisputeResource($dispute), 'Dispute created', 201);
    }

    public function show(Dispute $dispute): JsonResponse
    {
        $dispute->load(['booking.car:id,make,model,year', 'reporter:id,name', 'resolver:id,name']);
        return $this->success(new DisputeResource($dispute));
    }
}
