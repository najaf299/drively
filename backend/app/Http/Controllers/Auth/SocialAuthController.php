<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SocialAuthController extends Controller
{
    public function google(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id_token' => ['required', 'string'],
        ]);

        // Google ID token verification placeholder
        return $this->success(message: 'Google auth placeholder');
    }

    public function apple(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'identity_token' => ['required', 'string'],
            'authorization_code' => ['required', 'string'],
        ]);

        // Apple Sign In verification placeholder
        return $this->success(message: 'Apple auth placeholder');
    }
}
