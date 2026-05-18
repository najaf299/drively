<?php

namespace App\Enums;

enum ReviewType: string
{
    case Car = 'car';
    case Host = 'host';
    case Customer = 'customer';
}
