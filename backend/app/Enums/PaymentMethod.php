<?php

namespace App\Enums;

enum PaymentMethod: string
{
    case Card = 'card';
    case Wallet = 'wallet';
    case ApplePay = 'apple_pay';
    case GooglePay = 'google_pay';
}
