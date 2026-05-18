<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'kyc_status' => $this->kyc_status,
            'avatar_url' => $this->avatar_url,
            'date_of_birth' => $this->date_of_birth,
            'bio' => $this->bio,
            'average_rating' => $this->average_rating,
            'total_trips' => $this->total_trips,
            'preferred_language' => $this->preferred_language,
            'preferred_currency' => $this->preferred_currency,
            'preferred_units' => $this->preferred_units,
            'notification_settings' => $this->notification_settings,
            'is_suspended' => $this->is_suspended,
            'referral_code' => $this->referral_code,
            'email_verified_at' => $this->email_verified_at?->toISOString(),
            'phone_verified_at' => $this->phone_verified_at?->toISOString(),
            'host_verification' => new HostVerificationResource($this->whenLoaded('hostVerification')),
            'wallet' => new WalletResource($this->whenLoaded('wallet')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
