<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\CarResource;
use App\Models\Favorite;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $favorites = Favorite::where('user_id', $request->user()->id)
            ->with('car.photos')
            ->paginate(20);

        return $this->success(CarResource::collection($favorites->pluck('car')));
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
