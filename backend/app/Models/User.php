<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, HasUuids, Notifiable, SoftDeletes, HasRoles;

    protected $fillable = [
        'name', 'email', 'phone', 'password', 'role', 'kyc_status',
        'avatar_url', 'google_id', 'apple_id', 'average_rating', 'total_trips',
        'preferred_language', 'preferred_currency', 'preferred_units',
        'notification_settings', 'is_suspended', 'suspension_reason',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'password' => 'hashed',
            'notification_settings' => 'array',
            'is_suspended' => 'boolean',
            'average_rating' => 'decimal:2',
        ];
    }

    public function cars(): HasMany { return $this->hasMany(Car::class, 'host_id'); }
    public function bookings(): HasMany { return $this->hasMany(Booking::class, 'customer_id'); }
    public function reviews(): HasMany { return $this->hasMany(Review::class, 'reviewer_id'); }
    public function wallet(): HasOne { return $this->hasOne(Wallet::class); }
    public function kycDocuments(): HasMany { return $this->hasMany(KycDocument::class); }
    public function hostVerification(): HasOne { return $this->hasOne(HostVerification::class); }
    public function deviceTokens(): HasMany { return $this->hasMany(DeviceToken::class); }
    public function favorites(): HasMany { return $this->hasMany(Favorite::class); }
    public function earnings(): HasMany { return $this->hasMany(Earning::class, 'host_id'); }

    public function isHost(): bool { return $this->role === 'host'; }
    public function isAdmin(): bool { return $this->role === 'admin'; }
    public function isKycApproved(): bool { return $this->kyc_status === 'approved'; }
}
