<?php

namespace App\Models;

use App\Enums\InspectionType;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Inspection extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'trip_id', 'type', 'zones', 'photo_urls', 'notes', 'mileage',
        'fuel_level', 'renter_signature_url', 'host_signature_url',
        'damage_reported', 'damage_description',
    ];

    protected function casts(): array
    {
        return [
            'zones' => 'array',
            'photo_urls' => 'array',
            'damage_reported' => 'boolean',
            'type' => InspectionType::class,
        ];
    }

    public function trip(): BelongsTo { return $this->belongsTo(Trip::class); }
}
