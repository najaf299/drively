<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CarPhoto extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['car_id', 'url', 'thumbnail_url', 'order', 'is_cover'];
    protected function casts(): array { return ['is_cover' => 'boolean']; }
    public function car(): BelongsTo { return $this->belongsTo(Car::class); }
}
