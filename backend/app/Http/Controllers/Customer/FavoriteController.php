<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\CarResource;
use App\Models\Car;
use App\Models\Favorite;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        // Query Cars directly (joined to favorites) so the response is a real
        // paginator — the old `paginate()->pluck('car')` threw the pagination
        // meta away and lazy-loaded each car's host (N+1). Newest favourite
        // first; host + photos eager-loaded for CarResource.
        $cars = Car::query()
            ->select('cars.*')
            ->join('favorites', 'favorites.car_id', '=', 'cars.id')
            ->where('favorites.user_id', $request->user()->id)
            ->with(['photos', 'host:id,name,avatar_url,average_rating'])
            ->orderByDesc('favorites.created_at')
            ->paginate(20);

        return $this->success(CarResource::collection($cars));
    }

    public function toggle(Request $request): JsonResponse
    {
        $validated = $request->validate(['car_id' => ['required', 'uuid', 'exists:cars,id']]);

        $favorite = Favorite::where('user_id', $request->user()->id)
            ->where('car_id', $validated['car_id'])
            ->first();

        if ($favorite) {
            $favorite->delete();
            return $this->success(message: 'Removed from favorites');
        }

        Favorite::create(['user_id' => $request->user()->id, 'car_id' => $validated['car_id']]);
        return $this->success(message: 'Added to favorites', code: 201);
    }
}
