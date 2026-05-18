<?php

namespace App\Services;

use App\Enums\BookingStatus;
use App\Enums\TripStatus;
use App\Models\Booking;
use App\Models\Inspection;
use App\Models\Trip;

class TripService
{
    public function startTrip(Booking $booking, array $inspectionData = []): Trip
    {
        if ($booking->status !== BookingStatus::Confirmed) {
            throw new \RuntimeException('Booking must be confirmed to start a trip.');
        }

        $trip = Trip::create([
            'booking_id' => $booking->id,
            'status' => TripStatus::InProgress,
            'mileage_start' => $inspectionData['mileage'] ?? null,
            'fuel_level_start' => $inspectionData['fuel_level'] ?? null,
            'started_at' => now(),
        ]);

        $booking->update(['status' => BookingStatus::Active]);

        if (!empty($inspectionData)) {
            $this->createInspection($trip, 'pre_trip', $inspectionData);
        }

        return $trip;
    }

    public function endTrip(Trip $trip, array $inspectionData = []): Trip
    {
        if ($trip->status !== TripStatus::InProgress) {
            throw new \RuntimeException('Trip is not currently in progress.');
        }

        $trip->update([
            'status' => TripStatus::Completed,
            'mileage_end' => $inspectionData['mileage'] ?? null,
            'fuel_level_end' => $inspectionData['fuel_level'] ?? null,
            'ended_at' => now(),
        ]);

        if (!empty($inspectionData)) {
            $this->createInspection($trip, 'post_trip', $inspectionData);
        }

        return $trip->fresh();
    }

    public function createInspection(Trip $trip, string $type, array $data): Inspection
    {
        return Inspection::create([
            'trip_id' => $trip->id,
            'type' => $type,
            'zones' => $data['zones'] ?? [],
            'photo_urls' => $data['photo_urls'] ?? [],
            'notes' => $data['notes'] ?? null,
            'mileage' => $data['mileage'] ?? null,
            'fuel_level' => $data['fuel_level'] ?? null,
            'damage_reported' => $data['damage_reported'] ?? false,
            'damage_description' => $data['damage_description'] ?? null,
        ]);
    }

    public function updateLocation(Trip $trip, float $lat, float $lng): Trip
    {
        $trip->update([
            'last_known_lat' => $lat,
            'last_known_lng' => $lng,
            'location_updated_at' => now(),
        ]);

        return $trip;
    }

    public function extendTrip(Trip $trip, int $extraDays): Trip
    {
        $trip->update([
            'extended' => true,
            'extension_days' => ($trip->extension_days ?? 0) + $extraDays,
        ]);

        $booking = $trip->booking;
        $newReturnAt = $booking->return_at->addDays($extraDays);
        $booking->update(['return_at' => $newReturnAt]);

        return $trip->fresh();
    }
}
