<?php

namespace App\Http\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;

class CreateBookingRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'car_id' => ['required', 'uuid', 'exists:cars,id'],
            'pickup_at' => ['required', 'date', 'after:now'],
            'return_at' => ['required', 'date', 'after:pickup_at'],
            'pickup_address' => ['required', 'string'],
            'addons' => ['nullable', 'array'],
            'promo_code' => ['nullable', 'string', 'exists:promo_codes,code'],
        ];
    }
}
