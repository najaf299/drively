<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inspections', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['pre_trip', 'post_trip']);
            $table->json('zones');
            $table->json('photo_urls')->nullable();
            $table->text('notes')->nullable();
            $table->integer('mileage');
            $table->tinyInteger('fuel_level');
            $table->string('renter_signature_url')->nullable();
            $table->string('host_signature_url')->nullable();
            $table->boolean('damage_reported')->default(false);
            $table->text('damage_description')->nullable();
            $table->timestamps();
            $table->unique(['trip_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspections');
    }
};
