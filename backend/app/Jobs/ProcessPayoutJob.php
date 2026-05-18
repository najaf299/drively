<?php

namespace App\Jobs;

use App\Models\Earning;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ProcessPayoutJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(private Earning $earning) {}

    public function handle(): void
    {
        try {
            $this->earning->update([
                'status' => 'paid',
                'paid_at' => now(),
            ]);

            Log::info('Payout processed', ['earning_id' => $this->earning->id]);
        } catch (\Exception $e) {
            Log::error('Payout failed', [
                'earning_id' => $this->earning->id,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
