<?php

namespace App\Enums;

enum FuelPolicy: string
{
    case FullToFull = 'full_to_full';
    case FullToEmpty = 'full_to_empty';
    case SameLevel = 'same_level';
}
