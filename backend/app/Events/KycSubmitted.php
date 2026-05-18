<?php

namespace App\Events;

use App\Models\KycDocument;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class KycSubmitted
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public KycDocument $document) {}
}
