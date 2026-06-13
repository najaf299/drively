<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function __construct(private NotificationService $notificationService) {}

    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()
            ->notifications()
            ->when($request->unread_only, fn ($q) => $q->whereNull('read_at'))
            ->paginate($request->per_page ?? 20);

        return $this->success($notifications);
    }

    public function markAsRead(Request $request, string $id): JsonResponse
    {
        $notification = $request->user()->notifications()->findOrFail($id);
        $notification->markAsRead();
        return $this->success(message: 'Notification marked as read');
    }

    public function markAllRead(Request $request): JsonResponse
    {
        // Single UPDATE instead of loading every unread row and marking it
        // one-by-one (avoids an N+1 on busy accounts).
        $request->user()->unreadNotifications()->update(['read_at' => now()]);
        return $this->success(message: 'All notifications marked as read');
    }

    public function registerDevice(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => ['required', 'string'],
            'platform' => ['required', 'in:ios,android,web'],
        ]);

        $device = $this->notificationService->registerDeviceToken(
            $request->user(),
            $validated['token'],
            $validated['platform'],
        );

        return $this->success($device, 'Device registered', 201);
    }

    public function unregisterDevice(Request $request): JsonResponse
    {
        $validated = $request->validate(['token' => ['required', 'string']]);
        $this->notificationService->removeDeviceToken($validated['token']);
        return $this->success(message: 'Device unregistered');
    }
}
