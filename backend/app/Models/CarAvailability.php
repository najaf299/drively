<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CarAvailability extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['car_id', 'date', 'status', 'reason'];
    protected function casts(): array { return ['date' => 'date']; }
    public function car(): BelongsTo { return $this->belongsTo(Car::class); }
}
