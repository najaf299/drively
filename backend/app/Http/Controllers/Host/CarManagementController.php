<?php

namespace App\Http\Controllers\Host;

use App\Http\Controllers\Controller;
use App\Http\Resources\CarResource;
use App\Models\Car;
use App\Models\CarPhoto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CarManagementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $cars = Car::where('host_id', $request->user()->id)
            ->with('photos')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->orderByDesc('created_at')
            ->paginate(20);

        return $this->success(CarResource::collection($cars));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'make' => ['required', 'string', 'max:100'],
            'model' => ['required', 'string', 'max:100'],
            'year' => ['required', 'integer', 'min:2000', 'max:' . (date('Y') + 1)],
            'trim' => ['nullable', 'string', 'max:100'],
            'plate_number' => ['required', 'string', 'max:20'],
            'transmission' => ['required', 'in:automatic,manual'],
            'fuel_type' => ['required', 'in:petrol,diesel,electric,hybrid'],
            'seats' => ['required', 'integer', 'min:1', 'max:15'],
            'doors' => ['required', 'integer', 'min:2', 'max:6'],
            'daily_price' => ['required', 'numeric', 'min:1', 'max:99999'],
            'weekly_discount_pct' => ['nullable', 'numeric', 'min:0', 'max:50'],
            'monthly_discount_pct' => ['nullable', 'numeric', 'min:0', 'max:60'],
            'description' => ['nullable', 'string', 'max:2000'],
            'features' => ['required', 'array', 'min:1'],
            'features.*' => ['string'],
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'address' => ['required', 'string', 'max:500'],
            'city' => ['required', 'string', 'max:100'],
            'country' => ['required', 'string', 'size:2'],
            'mileage_limit_per_day' => ['nullable', 'integer', 'min:50'],
            'excess_mileage_fee' => ['nullable', 'numeric', 'min:0'],
            'fuel_policy' => ['required', 'in:full_to_full,full_to_empty,same_level'],
            'smoking_allowed' => ['nullable', 'boolean'],
            'pets_allowed' => ['nullable', 'boolean'],
            'photos' => ['nullable', 'array'],
            'photos.*.url' => ['required_with:photos', 'url'],
            'photos.*.is_cover' => ['nullable', 'boolean'],
        ]);

        $validated['host_id'] = $request->user()->id;
        $validated['status'] = 'draft';

        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $car = Car::create($validated);

        foreach ($photos as $index => $photo) {
            CarPhoto::create([
                'car_id' => $car->id,
                'url' => $photo['url'],
                'order' => $index,
                'is_cover' => $photo['is_cover'] ?? ($index === 0),
            ]);
        }

        return $this->success(new CarResource($car->load('photos')), 'Car listed', 201);
    }

    public function update(Request $request, Car $car): JsonResponse
    {
        if ($car->host_id !== $request->user()->id) {
            return $this->error('Unauthorized', 403);
        }

        $validated = $request->validate([
            'daily_price' => ['sometimes', 'numeric', 'min:1'],
            'weekly_discount_pct' => ['sometimes', 'numeric', 'min:0', 'max:50'],
            'monthly_discount_pct' => ['sometimes', 'numeric', 'min:0', 'max:60'],
            'description' => ['sometimes', 'string', 'max:2000'],
            'features' => ['sometimes', 'array'],
            'address' => ['sometimes', 'string', 'max:500'],
            'lat' => ['sometimes', 'numeric'],
            'lng' => ['sometimes', 'numeric'],
            'mileage_limit_per_day' => ['sometimes', 'integer', 'min:50'],
            'excess_mileage_fee' => ['sometimes', 'numeric', 'min:0'],
            'fuel_policy' => ['sometimes', 'in:full_to_full,full_to_empty,same_level'],
            'smoking_allowed' => ['sometimes', 'boolean'],
            'pets_allowed' => ['sometimes', 'boolean'],
            'dynamic_pricing_enabled' => ['sometimes', 'boolean'],
            'status' => ['sometimes', 'in:draft,active,paused'],
        ]);

        $car->update($validated);
        return $this->success(new CarResource($car->fresh()->load('photos')), 'Car updated');
    }

    public function destroy(Request $request, Car $car): JsonResponse
    {
        if ($car->host_id !== $request->user()->id) {
            return $this->error('Unauthorized', 403);
        }

        $activeBookings = $car->bookings()->whereIn('status', ['pending', 'confirmed', 'active'])->count();
        if ($activeBookings > 0) {
            return $this->error('Cannot delete car with active bookings.', 422);
        }

        $car->delete();
        return $this->success(message: 'Car deleted');
    }

    public function addPhotos(Request $request, Car $car): JsonResponse
    {
        if ($car->host_id !== $request->user()->id) {
            return $this->error('Unauthorized', 403);
        }

        $validated = $request->validate([
            'photos' => ['required', 'array', 'min:1'],
            'photos.*.url' => ['required', 'url'],
            'photos.*.is_cover' => ['nullable', 'boolean'],
        ]);

        $maxOrder = $car->photos()->max('order') ?? -1;

        foreach ($validated['photos'] as $index => $photo) {
            CarPhoto::create([
                'car_id' => $car->id,
                'url' => $photo['url'],
                'order' => $maxOrder + $index + 1,
                'is_cover' => $photo['is_cover'] ?? false,
            ]);
        }

        return $this->success($car->photos()->orderBy('order')->get(), 'Photos added', 201);
    }

    public function deletePhoto(Request $request, Car $car, CarPhoto $photo): JsonResponse
    {
        if ($car->host_id !== $request->user()->id) {
            return $this->error('Unauthorized', 403);
        }

        $photo->delete();
        return $this->success(message: 'Photo deleted');
    }
}
