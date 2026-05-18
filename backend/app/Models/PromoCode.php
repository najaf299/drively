<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PromoCode extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'code', 'type', 'value', 'max_discount', 'min_booking_amount',
        'max_uses', 'used_count', 'max_uses_per_user', 'valid_from', 'valid_until', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'value' => 'decimal:2',
            'max_discount' => 'decimal:2',
            'min_booking_amount' => 'decimal:2',
            'valid_from' => 'date',
            'valid_until' => 'date',
            'is_active' => 'boolean',
        ];
    }

    public function scopeValid($query)
    {
        return $query->where('is_active', true)
            ->where('valid_from', '<=', now())
            ->where('valid_until', '>=', now())
            ->whereColumn('used_count', '<', 'max_uses');
    }

    public function isValid(): bool
    {
        return $this->is_active
            && $this->valid_from <= now()
            && $this->valid_until >= now()
            && $this->used_count < $this->max_uses;
    }

    public function calculateDiscount(float $subtotal): float
    {
        if ($subtotal < ($this->min_booking_amount ?? 0)) {
            return 0;
        }

        $discount = $this->type === 'percentage'
            ? $subtotal * ($this->value / 100)
            : $this->value;

        if ($this->max_discount && $discount > $this->max_discount) {
            $discount = $this->max_discount;
        }

        return round(min($discount, $subtotal), 2);
    }
}
