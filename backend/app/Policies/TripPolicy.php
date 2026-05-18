<?php

namespace App\Policies;

use App\Models\Trip;
use App\Models\User;

class TripPolicy
{
    public function view(User $user, Trip $trip): bool
    {
        return $user->id === $trip->booking->customer_id
            || $user->id === $trip->booking->car->host_id
            || $user->isAdmin();
    }

    public function update(User $user, Trip $trip): bool
    {
        return $user->id === $trip->booking->customer_id
            || $user->id === $trip->booking->car->host_id;
    }
}
