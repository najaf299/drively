<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SendMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'recipient_id' => ['required', 'uuid', 'exists:users,id'],
            'content' => ['required_without:image_url', 'string', 'max:5000'],
            'type' => ['sometimes', 'string', 'in:text,image,booking_action'],
            'image_url' => ['sometimes', 'url'],
            'booking_id' => ['sometimes', 'uuid', 'exists:bookings,id'],
        ];
    }
}
