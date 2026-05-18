<?php

namespace App\Models;

use App\Enums\TripStatus;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Trip extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'booking_id', 'status', 'mileage_start', 'mileage_end',
        'fuel_level_start', 'fuel_level_end', 'started_at', 'ended_at',
        'last_known_lat', 'last_known_lng', 'location_updated_at',
        'extended', 'extension_days',
    ];

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
            'location_updated_at' => 'datetime',
            'extended' => 'boolean',
            'status' => TripStatus::class,
            'last_known_lat' => 'decimal:7',
            'last_known_lng' => 'decimal:7',
        ];
    }

    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
    public function inspections(): HasMany { return $this->hasMany(Inspection::class); }

    public function preInspection()
    {
        return $this->inspections()->where('type', 'pre_trip')->first();
    }

    public function postInspection()
    {
        return $this->inspections()->where('type', 'post_trip')->first();
    }

    public function totalMileage(): ?int
    {
        if ($this->mileage_start === null || $this->mileage_end === null) {
            return null;
        }
        return $this->mileage_end - $this->mileage_start;
    }

    public function isOverdue(): bool
    {
        return $this->status === TripStatus::InProgress
            && $this->booking->return_at->isPast();
    }
}
