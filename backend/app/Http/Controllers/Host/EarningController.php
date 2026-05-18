<?php

namespace App\Http\Controllers\Host;

use App\Http\Controllers\Controller;
use App\Models\Earning;
use App\Services\HostService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EarningController extends Controller
{
    public function __construct(private HostService $hostService) {}

    public function index(Request $request): JsonResponse
    {
        $period = $request->get('period', 'month');
        $summary = $this->hostService->calculateEarnings($request->user()->id, $period);

        return $this->success($summary);
    }

    public function history(Request $request): JsonResponse
    {
        $earnings = Earning::where('host_id', $request->user()->id)
            ->with(['booking.car:id,make,model,year', 'booking.customer:id,name'])
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success($earnings);
    }
}
