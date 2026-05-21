<?php

namespace Database\Seeders;

use App\Models\Booking;
use App\Models\Car;
use App\Models\ChatMessage;
use App\Models\ChatThread;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class ChatSeeder extends Seeder
{
    /**
     * Seed chat threads + messages between customers and hosts so the Messages
     * tab always has real conversations — including for demo accounts that have
     * no bookings yet (threads link to a booking when one exists, else null).
     */
    public function run(): void
    {
        $hosts = User::where('role', 'host')->get();
        if ($hosts->isEmpty()) {
            $this->command?->warn('No hosts to seed chats with.');
            return;
        }

        $customers = User::where('role', 'customer')->take(8)->get();
        $count = 0;

        foreach ($customers as $customer) {
            $chosenHosts = $hosts->where('id', '!=', $customer->id)->take(2);

            foreach ($chosenHosts as $host) {
                // Skip if these two already share a thread (either order).
                $exists = ChatThread::query()
                    ->where(fn ($q) => $q
                        ->where('participant_one', $customer->id)
                        ->where('participant_two', $host->id))
                    ->orWhere(fn ($q) => $q
                        ->where('participant_one', $host->id)
                        ->where('participant_two', $customer->id))
                    ->exists();
                if ($exists) {
                    continue;
                }

                // Attach a real booking if one exists between this pair.
                $booking = Booking::where('customer_id', $customer->id)
                    ->whereHas('car', fn ($q) => $q->where('host_id', $host->id))
                    ->first();
                $car = $booking?->car ?? Car::where('host_id', $host->id)->first();

                $thread = ChatThread::create([
                    'booking_id' => $booking?->id,
                    'participant_one' => $customer->id,
                    'participant_two' => $host->id,
                    'is_archived' => false,
                ]);

                $carName = trim(($car?->make ?? '').' '.($car?->model ?? ''));
                $carName = $carName !== '' ? $carName : 'the car';

                // [sender, content] — c = customer, h = host.
                $script = [
                    ['c', "Hi! Is the {$carName} available for my dates?"],
                    ['h', 'Hey! Yes, it\'s all yours. Pick-up anytime after 10am works.'],
                    ['c', 'Perfect — where should I collect it?'],
                    ['h', 'I\'ll drop the exact pickup pin here once it\'s confirmed. It\'s near the Marina.'],
                    ['c', 'Awesome, thank you! 🙌'],
                    ['h', 'See you then. Drive safe! 🚗'],
                ];

                $base = Carbon::now()->subDays(rand(0, 3))->subHours(rand(1, 6));

                foreach ($script as $i => [$who, $content]) {
                    $senderId = $who === 'c' ? $customer->id : $host->id;
                    $sentAt = (clone $base)->addMinutes($i * 7);
                    $isLast = $i === count($script) - 1;

                    ChatMessage::create([
                        'thread_id' => $thread->id,
                        'sender_id' => $senderId,
                        'type' => 'text',
                        'content' => $content,
                        // Leave the final host reply unread so the dot shows.
                        'read_at' => $isLast && $who === 'h' ? null : $sentAt,
                        'delivered_at' => $sentAt,
                        'created_at' => $sentAt,
                        'updated_at' => $sentAt,
                    ]);
                }

                $count++;
            }
        }

        $this->command?->info("Seeded {$count} chat thread(s).");
    }
}
