<?php

namespace App\Http\Requests\Host;

use Illuminate\Foundation\Http\FormRequest;

class StoreCarRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'make' => ['required', 'string', 'max:100'],
            'model' => ['required', 'string', 'max:100'],
            'year' => ['required', 'integer', 'min:2000', 'max:' . (date('Y') + 1)],
            'plate_number' => ['required', 'string'],
            'transmission' => ['required', 'in:automatic,manual'],
            'fuel_type' => ['required', 'in:petrol,diesel,electric,hybrid'],
            'seats' => ['required', 'integer', 'min:1', 'max:15'],
            'doors' => ['required', 'integer', 'min:2', 'max:6'],
            'daily_price' => ['required', 'numeric', 'min:1'],
            'weekly_discount_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'monthly_discount_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'description' => ['nullable', 'string', 'max:2000'],
            'features' => ['required', 'array'],
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'address' => ['required', 'string'],
            'city' => ['required', 'string'],
            'country' => ['required', 'string', 'size:2'],
            'fuel_policy' => ['required', 'in:full_to_full,full_to_empty,same_level'],
            'mileage_limit_per_day' => ['nullable', 'integer', 'min:0'],
            'excess_mileage_fee' => ['nullable', 'numeric', 'min:0'],
            'smoking_allowed' => ['nullable', 'boolean'],
            'pets_allowed' => ['nullable', 'boolean'],
        ];
    }
}
