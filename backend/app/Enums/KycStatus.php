<?php

namespace App\Enums;

enum KycStatus: string
{
    case None = 'none';
    case Pending = 'pending';
    case InReview = 'in_review';
    case Approved = 'approved';
    case Rejected = 'rejected';
}
