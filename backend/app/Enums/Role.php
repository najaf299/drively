<?php

namespace App\Enums;

enum Role: string
{
    case Customer = 'customer';
    case Host = 'host';
    case Admin = 'admin';
}
