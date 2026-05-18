<?php

namespace App\Enums;

enum TripStatus: string
{
    case Pending = 'pending';
    case InProgress = 'in_progress';
    case Overdue = 'overdue';
    case Completed = 'completed';
}
