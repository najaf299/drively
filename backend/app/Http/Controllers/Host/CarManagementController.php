<?php

namespace App\Http\Controllers\Host;

use App\Http\Controllers\Controller;
use App\Http\Resources\CarResource;
use App\Models\Car;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CarManagementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $cars = Car::where('host_id', $request->user()->id)
            ->with('photos')
            ->orderByDesc('created_at')
            ->paginate(20);

        return $this->success(CarResource::collection($cars));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'make' => ['required', 'string'], 'model' => ['required', 'string'],
            'year' => ['required', 'integer', 'min:2000'], 'plate_number' => ['required', 'string'],
            'transmission' => ['required', 'in:automatic,manual'],
            'fuel_type' => ['required', 'in:petrol,diesel,electric,hybrid'],
            'seats' => ['required', 'integer', 'min:1'], 'doors' => ['required', 'integer', 'min:2'],
            'daily_price' => ['required', 'numeric', 'min:1'],
            'description' => ['nullable', 'string'], 'features' => ['required', 'array'],
            'lat' => ['required', 'numeric'], 'lng' => ['required', 'numeric'],
            'address' => ['required', 'string'], 'city' => ['required', 'string'],
            'country' => ['required', 'string', 'size:2'],
            'fuel_policy' => ['required', 'in:full_to_full,full_to_empty,same_level'],
        ]);

        $validated['host_id'] = $request->user()->id;
        $validated['status'] = 'draft';
        $car = Car::create($validated);

        return $this->success(new CarResource($car), 'Car listed', 201);
    }

    public function update(Request $request, Car $car): JsonResponse
    {
        $this->authorize('update', $car);
        $car->update($request->validated());
        return $this->success(new CarResource($car->fresh()));
    }

    public function destroy(Car $car): JsonResponse
    {
        $this->authorize('delete', $car);
        $car->delete();
        return $this->success(message: 'Car deleted');
    }
}
