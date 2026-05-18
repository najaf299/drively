<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return $this->success($request->user()->load(['wallet', 'kycDocuments']));
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'avatar_url' => ['sometimes', 'string', 'url'],
            'preferred_language' => ['sometimes', 'string', 'in:en,ar,fr,es,de'],
            'preferred_currency' => ['sometimes', 'string', 'size:3'],
            'preferred_units' => ['sometimes', 'in:km,mi'],
            'notification_settings' => ['sometimes', 'array'],
        ]);

        $request->user()->update($validated);
        return $this->success($request->user()->fresh());
    }
}
