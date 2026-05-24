<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Repairs the `notifications` table on existing databases.
 *
 * The original migration created a non-standard schema (user_id/title/body/
 * is_read) but the app uses Laravel's Notifiable database channel, which
 * requires the framework schema (type/notifiable morph/data/read_at). That
 * mismatch caused "Unknown column 'read_at'" when sending notifications (e.g.
 * on new bookings). This drops the old table and recreates the correct one.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('notifications');

        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('type');
            $table->uuidMorphs('notifiable');
            $table->text('data');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
