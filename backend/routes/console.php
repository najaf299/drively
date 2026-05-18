<?php

use App\Jobs\ProcessBookingExpiry;
use Illuminate\Support\Facades\Schedule;

Schedule::job(new ProcessBookingExpiry)->hourly();
