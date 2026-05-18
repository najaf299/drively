<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('reference')->unique();
            $table->foreignUuid('car_id')->constrained()->restrictOnDelete();
            $table->foreignUuid('customer_id')->constrained('users')->restrictOnDelete();
            $table->datetime('pickup_at');
            $table->datetime('return_at');
            $table->decimal('daily_rate', 8, 2);
            $table->tinyInteger('total_days');
            $table->decimal('subtotal', 10, 2);
            $table->decimal('addons_total', 10, 2)->default(0);
            $table->decimal('service_fee', 10, 2)->default(0);
            $table->decimal('tax', 10, 2)->default(0);
            $table->decimal('discount', 10, 2)->default(0);
            $table->decimal('total_amount', 10, 2);
            $table->json('addons')->nullable();
            $table->string('pickup_address');
            $table->enum('booking_type', ['instant', 'request'])->default('instant');
            $table->enum('status', ['pending', 'confirmed', 'active', 'completed', 'cancelled', 'declined'])->default('pending');
            $table->string('cancellation_reason')->nullable();
            $table->foreignUuid('promo_code_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamp('host_response_deadline')->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->index(['customer_id', 'status']);
            $table->index(['car_id', 'pickup_at', 'return_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
