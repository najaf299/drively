<?php

namespace App\Filament\Widgets;

use App\Models\Booking;
use App\Models\Car;
use App\Models\Payment;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

/**
 * Top-of-dashboard KPI cards mirroring the metrics that matter in the Drivly
 * app: members, fleet size, bookings and collected revenue.
 */
class StatsOverview extends BaseWidget
{
    protected static ?int $sort = -2;

    protected function getStats(): array
    {
        $revenue = (float) Payment::where('status', 'succeeded')->sum('amount');
        $activeTrips = Booking::where('status', 'active')->count();

        return [
            Stat::make('Members', number_format(User::count()))
                ->description('Registered drivers & hosts')
                ->descriptionIcon('heroicon-m-users')
                ->color('primary'),

            Stat::make('Cars listed', number_format(Car::count()))
                ->description('Across the fleet')
                ->descriptionIcon('heroicon-m-truck')
                ->color('primary'),

            Stat::make('Bookings', number_format(Booking::count()))
                ->description($activeTrips . ' active right now')
                ->descriptionIcon('heroicon-m-calendar-days')
                ->color('info'),

            Stat::make('Revenue', '$' . number_format($revenue, 2))
                ->description('Collected payments')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),
        ];
    }
}
