<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreDisputeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'type' => ['required', 'string', 'in:damage,late_return,cleanliness,other'],
            'description' => ['required', 'string', 'max:5000'],
            'evidence_urls' => ['sometimes', 'array'],
            'evidence_urls.*' => ['url'],
        ];
    }
}
