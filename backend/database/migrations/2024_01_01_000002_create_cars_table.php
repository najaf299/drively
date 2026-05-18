<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cars', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('host_id')->constrained('users')->cascadeOnDelete();
            $table->string('make');
            $table->string('model');
            $table->smallInteger('year');
            $table->string('trim')->nullable();
            $table->string('plate_number');
            $table->enum('transmission', ['automatic', 'manual']);
            $table->enum('fuel_type', ['petrol', 'diesel', 'electric', 'hybrid']);
            $table->tinyInteger('seats');
            $table->tinyInteger('doors');
            $table->decimal('daily_price', 8, 2);
            $table->decimal('weekly_discount_pct', 5, 2)->default(0);
            $table->decimal('monthly_discount_pct', 5, 2)->default(0);
            $table->boolean('dynamic_pricing_enabled')->default(false);
            $table->decimal('suggested_price', 8, 2)->nullable();
            $table->text('description')->nullable();
            $table->json('features');
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->string('address');
            $table->string('city');
            $table->string('country', 2);
            $table->integer('mileage_limit_per_day')->nullable();
            $table->decimal('excess_mileage_fee', 6, 2)->nullable();
            $table->enum('fuel_policy', ['full_to_full', 'full_to_empty', 'same_level']);
            $table->boolean('smoking_allowed')->default(false);
            $table->boolean('pets_allowed')->default(false);
            $table->decimal('average_rating', 3, 2)->default(0);
            $table->integer('total_trips')->default(0);
            $table->integer('total_reviews')->default(0);
            $table->enum('status', ['draft', 'pending_approval', 'active', 'suspended', 'deleted'])->default('draft');
            $table->string('rejection_reason')->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->index(['city', 'status']);
            $table->index(['lat', 'lng']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cars');
    }
};
