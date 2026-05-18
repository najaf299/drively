<?php

namespace App\Events;

use App\Models\User;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class KycStatusUpdated
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    public function __construct(public User $user, public string $status) {}
}
