<?php

namespace App\Providers;

use App\Models\Booking;
use App\Models\Car;
use App\Models\Dispute;
use App\Models\Trip;
use App\Policies\BookingPolicy;
use App\Policies\CarPolicy;
use App\Policies\DisputePolicy;
use App\Policies\TripPolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [
        Booking::class => BookingPolicy::class,
        Car::class => CarPolicy::class,
        Trip::class => TripPolicy::class,
        Dispute::class => DisputePolicy::class,
    ];

    public function boot(): void
    {
        $this->registerPolicies();
    }
}
