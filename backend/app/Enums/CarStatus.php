<?php

namespace App\Enums;

enum CarStatus: string
{
    case Draft = 'draft';
    case PendingApproval = 'pending_approval';
    case Active = 'active';
    case Suspended = 'suspended';
    case Deleted = 'deleted';
}
