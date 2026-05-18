<?php

namespace App\Http\Controllers\Host;

use App\Http\Controllers\Controller;
use App\Services\HostService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EarningController extends Controller
{
    public function __construct(private HostService $hostService) {}

    public function index(Request $request): JsonResponse
    {
        $period = $request->get('period', 'month');
        $earnings = $this->hostService->calculateEarnings($request->user()->id, $period);
        return $this->success($earnings);
    }
}
