<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class KycDocumentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'type' => ['required', 'string', 'in:national_id,passport,driving_license,utility_bill,selfie'],
            'document_url' => ['required', 'url'],
            'document_number' => ['sometimes', 'string', 'max:100'],
            'expiry_date' => ['sometimes', 'date', 'after:today'],
        ];
    }
}
