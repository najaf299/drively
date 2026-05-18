<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
*/

Broadcast::channel('chat.thread.{threadId}', function ($user, $threadId) {
    $thread = \App\Models\ChatThread::find($threadId);
    if (!$thread) return false;
    return $user->id === $thread->participant_one || $user->id === $thread->participant_two;
});

Broadcast::channel('user.{userId}', function ($user, $userId) {
    return $user->id === $userId;
});

Broadcast::channel('booking.{bookingId}', function ($user, $bookingId) {
    $booking = \App\Models\Booking::find($bookingId);
    if (!$booking) return false;
    return $user->id === $booking->customer_id || $user->id === $booking->car->host_id;
});
