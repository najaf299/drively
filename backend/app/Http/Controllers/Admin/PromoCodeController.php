<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PromoCodeController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $promoCodes = PromoCode::orderByDesc('created_at')
            ->when($request->boolean('active_only'), fn ($q) => $q->where('is_active', true))
            ->paginate($request->per_page ?? 20);

        return $this->success($promoCodes);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['required', 'string', 'unique:promo_codes,code'],
            'type' => ['required', 'in:percentage,fixed'],
            'value' => ['required', 'numeric', 'min:0'],
            'max_discount' => ['nullable', 'numeric', 'min:0'],
            'min_booking_amount' => ['nullable', 'numeric', 'min:0'],
            'max_uses' => ['required', 'integer', 'min:1'],
            'max_uses_per_user' => ['nullable', 'integer', 'min:1'],
            'valid_from' => ['required', 'date'],
            'valid_until' => ['required', 'date', 'after:valid_from'],
        ]);

        $validated['is_active'] = true;
        $validated['used_count'] = 0;
        $promo = PromoCode::create($validated);

        return $this->success($promo, 'Promo code created', 201);
    }

    public function update(Request $request, PromoCode $promoCode): JsonResponse
    {
        $validated = $request->validate([
            'is_active' => ['sometimes', 'boolean'],
            'max_uses' => ['sometimes', 'integer', 'min:1'],
            'valid_until' => ['sometimes', 'date'],
        ]);

        $promoCode->update($validated);
        return $this->success($promoCode->fresh(), 'Promo code updated');
    }

    public function destroy(PromoCode $promoCode): JsonResponse
    {
        $promoCode->delete();
        return $this->success(message: 'Promo code deleted');
    }
}
