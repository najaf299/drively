<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('phone')->unique()->nullable();
            $table->timestamp('phone_verified_at')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password')->nullable();
            $table->enum('role', ['customer', 'host', 'admin'])->default('customer');
            $table->enum('kyc_status', ['none', 'pending', 'in_review', 'approved', 'rejected'])->default('none');
            $table->string('avatar_url')->nullable();
            $table->string('google_id')->nullable()->index();
            $table->string('apple_id')->nullable()->index();
            $table->decimal('average_rating', 3, 2)->default(0);
            $table->integer('total_trips')->default(0);
            $table->string('preferred_language', 5)->default('en');
            $table->string('preferred_currency', 3)->default('USD');
            $table->enum('preferred_units', ['km', 'mi'])->default('km');
            $table->json('notification_settings')->nullable();
            $table->boolean('is_suspended')->default(false);
            $table->string('suspension_reason')->nullable();
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignUuid('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};
