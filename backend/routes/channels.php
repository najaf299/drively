<?php

use App\Models\ChatThread;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('user.{id}', function ($user, $id) {
    return $user->id === $id;
});

Broadcast::channel('chat.thread.{threadId}', function ($user, $threadId) {
    $thread = ChatThread::find($threadId);
    return $thread && $thread->hasParticipant($user->id);
});

Broadcast::channel('booking.{bookingId}', function ($user, $bookingId) {
    $booking = \App\Models\Booking::find($bookingId);
    if (!$booking) return false;
    return $user->id === $booking->customer_id || $user->id === $booking->car->host_id;
});
