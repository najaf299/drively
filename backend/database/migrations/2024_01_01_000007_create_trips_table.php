<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trips', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('booking_id')->unique()->constrained()->cascadeOnDelete();
            $table->enum('status', ['pending', 'in_progress', 'overdue', 'completed'])->default('pending');
            $table->integer('mileage_start')->nullable();
            $table->integer('mileage_end')->nullable();
            $table->tinyInteger('fuel_level_start')->nullable();
            $table->tinyInteger('fuel_level_end')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->decimal('last_known_lat', 10, 7)->nullable();
            $table->decimal('last_known_lng', 10, 7)->nullable();
            $table->timestamp('location_updated_at')->nullable();
            $table->boolean('extended')->default(false);
            $table->integer('extension_days')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trips');
    }
};
