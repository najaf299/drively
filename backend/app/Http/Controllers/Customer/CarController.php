<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\CarResource;
use App\Models\Car;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CarController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $cars = Car::active()
            ->with(['photos', 'host:id,name,avatar_url,average_rating'])
            ->when($request->city, fn ($q, $city) => $q->where('city', $city))
            ->when($request->transmission, fn ($q, $t) => $q->where('transmission', $t))
            ->when($request->fuel_type, fn ($q, $f) => $q->where('fuel_type', $f))
            ->when($request->min_price, fn ($q, $p) => $q->where('daily_price', '>=', $p))
            ->when($request->max_price, fn ($q, $p) => $q->where('daily_price', '<=', $p))
            ->paginate($request->per_page ?? 20);

        return $this->success(CarResource::collection($cars));
    }

    public function show(Car $car): JsonResponse
    {
        $car->load(['photos', 'host:id,name,avatar_url,average_rating,total_trips', 'reviews.reviewer:id,name,avatar_url']);
        return $this->success(new CarResource($car));
    }
}
