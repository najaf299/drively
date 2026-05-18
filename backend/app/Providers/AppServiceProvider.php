<?php

namespace App\Providers;

use App\Events\BookingCancelled;
use App\Events\BookingCreated;
use App\Events\KycSubmitted;
use App\Listeners\NotifyAdminKycSubmission;
use App\Listeners\SendBookingNotification;
use App\Listeners\SendCancellationNotification;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        Event::listen(BookingCreated::class, SendBookingNotification::class);
        Event::listen(BookingCancelled::class, SendCancellationNotification::class);
        Event::listen(KycSubmitted::class, NotifyAdminKycSubmission::class);
    }
}
