<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCarRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'make' => ['required', 'string', 'max:100'],
            'model' => ['required', 'string', 'max:100'],
            'year' => ['required', 'integer', 'min:2015', 'max:' . (date('Y') + 1)],
            'trim' => ['sometimes', 'string', 'max:100'],
            'plate_number' => ['required', 'string', 'unique:cars,plate_number'],
            'transmission' => ['required', 'string', 'in:automatic,manual'],
            'fuel_type' => ['required', 'string', 'in:petrol,diesel,electric,hybrid'],
            'seats' => ['required', 'integer', 'min:1', 'max:12'],
            'doors' => ['required', 'integer', 'min:2', 'max:6'],
            'daily_price' => ['required', 'numeric', 'min:1'],
            'weekly_discount_pct' => ['sometimes', 'numeric', 'min:0', 'max:100'],
            'monthly_discount_pct' => ['sometimes', 'numeric', 'min:0', 'max:100'],
            'description' => ['sometimes', 'string', 'max:2000'],
            'features' => ['sometimes', 'array'],
            'features.*' => ['string'],
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'address' => ['required', 'string', 'max:500'],
            'city' => ['required', 'string', 'max:100'],
            'country' => ['required', 'string', 'max:10'],
            'mileage_limit_per_day' => ['sometimes', 'integer', 'min:50'],
            'excess_mileage_fee' => ['sometimes', 'numeric', 'min:0'],
            'fuel_policy' => ['sometimes', 'string', 'in:full_to_full,full_to_empty,same_level'],
            'smoking_allowed' => ['sometimes', 'boolean'],
            'pets_allowed' => ['sometimes', 'boolean'],
        ];
    }
}
