<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\CarResource;
use App\Models\Car;
use App\Services\PricingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CarController extends Controller
{
    public function __construct(private PricingService $pricingService) {}

    public function index(Request $request): JsonResponse
    {
        $query = Car::active()
            ->with(['photos', 'host:id,name,avatar_url,average_rating']);

        if ($request->has('lat') && $request->has('lng')) {
            $query->nearby(
                (float) $request->lat,
                (float) $request->lng,
                (float) ($request->radius ?? 25),
            );
        }

        $cars = $query
            ->when($request->city, fn ($q, $city) => $q->where('city', $city))
            ->when($request->country, fn ($q, $c) => $q->where('country', $c))
            ->when($request->transmission, fn ($q, $t) => $q->where('transmission', $t))
            ->when($request->fuel_type, fn ($q, $f) => $q->where('fuel_type', $f))
            ->when($request->min_price, fn ($q, $p) => $q->where('daily_price', '>=', $p))
            ->when($request->max_price, fn ($q, $p) => $q->where('daily_price', '<=', $p))
            ->when($request->min_year, fn ($q, $y) => $q->where('year', '>=', $y))
            ->when($request->max_year, fn ($q, $y) => $q->where('year', '<=', $y))
            ->when($request->min_seats, fn ($q, $s) => $q->where('seats', '>=', $s))
            ->when($request->make, fn ($q, $m) => $q->where('make', $m))
            ->when($request->sort === 'price_asc', fn ($q) => $q->orderBy('daily_price'))
            ->when($request->sort === 'price_desc', fn ($q) => $q->orderByDesc('daily_price'))
            ->when($request->sort === 'rating', fn ($q) => $q->orderByDesc('average_rating'))
            ->when(!$request->sort && !$request->has('lat'), fn ($q) => $q->orderByDesc('created_at'))
            ->paginate($request->per_page ?? 20);

        return $this->success(CarResource::collection($cars));
    }

    public function show(Car $car): JsonResponse
    {
        $car->load([
            'photos',
            'host:id,name,avatar_url,average_rating,total_trips',
            'reviews' => fn ($q) => $q->with('reviewer:id,name,avatar_url')->where('is_public', true)->latest()->limit(5),
        ]);

        $suggestedPrice = $this->pricingService->getSuggestedPrice($car);

        return $this->success([
            'car' => new CarResource($car),
            'suggested_price' => $suggestedPrice,
            'total_reviews' => $car->reviews()->count(),
        ]);
    }
}
