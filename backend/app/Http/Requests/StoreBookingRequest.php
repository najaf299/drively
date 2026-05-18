<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'car_id' => ['required', 'uuid', 'exists:cars,id'],
            'pickup_at' => ['required', 'date', 'after:now'],
            'return_at' => ['required', 'date', 'after:pickup_at'],
            'pickup_address' => ['sometimes', 'string', 'max:500'],
            'promo_code' => ['sometimes', 'string', 'exists:promo_codes,code'],
            'addons' => ['sometimes', 'array'],
            'addons.*.name' => ['required_with:addons', 'string'],
            'addons.*.price' => ['required_with:addons', 'numeric', 'min:0'],
        ];
    }
}
