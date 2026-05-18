<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCarRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'make' => ['sometimes', 'string', 'max:100'],
            'model' => ['sometimes', 'string', 'max:100'],
            'year' => ['sometimes', 'integer', 'min:2015', 'max:' . (date('Y') + 1)],
            'trim' => ['sometimes', 'string', 'max:100'],
            'plate_number' => ['sometimes', 'string', 'unique:cars,plate_number,' . $this->route('car')],
            'transmission' => ['sometimes', 'string', 'in:automatic,manual'],
            'fuel_type' => ['sometimes', 'string', 'in:petrol,diesel,electric,hybrid'],
            'seats' => ['sometimes', 'integer', 'min:1', 'max:12'],
            'doors' => ['sometimes', 'integer', 'min:2', 'max:6'],
            'daily_price' => ['sometimes', 'numeric', 'min:1'],
            'weekly_discount_pct' => ['sometimes', 'numeric', 'min:0', 'max:100'],
            'monthly_discount_pct' => ['sometimes', 'numeric', 'min:0', 'max:100'],
            'description' => ['sometimes', 'string', 'max:2000'],
            'features' => ['sometimes', 'array'],
            'lat' => ['sometimes', 'numeric', 'between:-90,90'],
            'lng' => ['sometimes', 'numeric', 'between:-180,180'],
            'address' => ['sometimes', 'string', 'max:500'],
            'city' => ['sometimes', 'string', 'max:100'],
            'country' => ['sometimes', 'string', 'max:10'],
            'mileage_limit_per_day' => ['sometimes', 'integer', 'min:50'],
            'excess_mileage_fee' => ['sometimes', 'numeric', 'min:0'],
            'fuel_policy' => ['sometimes', 'string', 'in:full_to_full,full_to_empty,same_level'],
            'smoking_allowed' => ['sometimes', 'boolean'],
            'pets_allowed' => ['sometimes', 'boolean'],
        ];
    }
}
