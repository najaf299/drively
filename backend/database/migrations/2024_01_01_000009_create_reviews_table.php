<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('reviewer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('reviewee_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('car_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('type', ['car', 'host', 'customer']);
            $table->tinyInteger('rating');
            $table->tinyInteger('cleanliness_rating')->nullable();
            $table->tinyInteger('communication_rating')->nullable();
            $table->tinyInteger('accuracy_rating')->nullable();
            $table->tinyInteger('pickup_rating')->nullable();
            $table->text('comment')->nullable();
            $table->json('tags')->nullable();
            $table->json('photo_urls')->nullable();
            $table->boolean('is_public')->default(true);
            $table->timestamps();
            $table->unique(['booking_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
