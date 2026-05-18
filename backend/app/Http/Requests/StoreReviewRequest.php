<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'cleanliness_rating' => ['sometimes', 'integer', 'min:1', 'max:5'],
            'communication_rating' => ['sometimes', 'integer', 'min:1', 'max:5'],
            'accuracy_rating' => ['sometimes', 'integer', 'min:1', 'max:5'],
            'pickup_rating' => ['sometimes', 'integer', 'min:1', 'max:5'],
            'comment' => ['sometimes', 'string', 'max:2000'],
            'tags' => ['sometimes', 'array'],
            'tags.*' => ['string'],
            'photo_urls' => ['sometimes', 'array'],
            'photo_urls.*' => ['url'],
            'is_public' => ['sometimes', 'boolean'],
        ];
    }
}
