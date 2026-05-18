<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserManagementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $users = User::query()
            ->when($request->role, fn ($q, $r) => $q->where('role', $r))
            ->when($request->kyc_status, fn ($q, $s) => $q->where('kyc_status', $s))
            ->when($request->search, fn ($q, $s) => $q->where(function ($q2) use ($s) {
                $q2->where('name', 'like', "%{$s}%")
                    ->orWhere('email', 'like', "%{$s}%")
                    ->orWhere('phone', 'like', "%{$s}%");
            }))
            ->when($request->boolean('suspended'), fn ($q) => $q->where('is_suspended', true))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return $this->success($users);
    }

    public function show(User $user): JsonResponse
    {
        $user->load(['wallet', 'kycDocuments', 'hostVerification', 'cars', 'bookings']);
        return $this->success($user);
    }

    public function suspend(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $user->update([
            'is_suspended' => true,
            'suspension_reason' => $validated['reason'],
        ]);

        $user->tokens()->delete();

        return $this->success($user->fresh(), 'User suspended');
    }

    public function unsuspend(User $user): JsonResponse
    {
        $user->update([
            'is_suspended' => false,
            'suspension_reason' => null,
        ]);

        return $this->success($user->fresh(), 'User unsuspended');
    }
}
