<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PromoCode extends Model
{
    use HasFactory, HasUuids;
    protected $fillable = ['code', 'type', 'value', 'max_discount', 'min_booking_amount', 'max_uses', 'used_count', 'max_uses_per_user', 'valid_from', 'valid_until', 'is_active'];
    protected function casts(): array { return ['value' => 'decimal:2', 'valid_from' => 'date', 'valid_until' => 'date', 'is_active' => 'boolean']; }
}
