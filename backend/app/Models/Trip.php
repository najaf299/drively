<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Trip extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['booking_id', 'status', 'mileage_start', 'mileage_end', 'fuel_level_start', 'fuel_level_end', 'started_at', 'ended_at', 'last_known_lat', 'last_known_lng', 'location_updated_at', 'extended', 'extension_days'];
    protected function casts(): array { return ['started_at' => 'datetime', 'ended_at' => 'datetime', 'location_updated_at' => 'datetime', 'extended' => 'boolean']; }
    public function booking(): BelongsTo { return $this->belongsTo(Booking::class); }
    public function inspections(): HasMany { return $this->hasMany(Inspection::class); }
}
