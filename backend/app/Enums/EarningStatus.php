<?php

namespace App\Enums;

enum EarningStatus: string
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Failed = 'failed';
}
