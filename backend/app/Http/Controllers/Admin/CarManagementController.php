<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\CarResource;
use App\Models\Car;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CarManagementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $cars = Car::with('host:id,name,email')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->city, fn ($q, $c) => $q->where('city', $c))
            ->when($request->search, fn ($q, $s) => $q->where(function ($q2) use ($s) {
                $q2->where('make', 'like', "%{$s}%")
                    ->orWhere('model', 'like', "%{$s}%")
                    ->orWhere('plate_number', 'like', "%{$s}%");
            }))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success(CarResource::collection($cars));
    }

    public function approve(Car $car): JsonResponse
    {
        $car->update(['status' => 'active']);
        return $this->success(new CarResource($car->fresh()), 'Car approved');
    }

    public function reject(Request $request, Car $car): JsonResponse
    {
        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $car->update([
            'status' => 'rejected',
            'rejection_reason' => $validated['reason'],
        ]);

        return $this->success(new CarResource($car->fresh()), 'Car rejected');
    }

    public function suspend(Car $car): JsonResponse
    {
        $car->update(['status' => 'suspended']);
        return $this->success(new CarResource($car->fresh()), 'Car suspended');
    }
}
