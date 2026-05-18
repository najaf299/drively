<?php

namespace App\Enums;

enum BookingType: string
{
    case Instant = 'instant';
    case Request = 'request';
}
