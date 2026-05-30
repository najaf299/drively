<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds the columns needed to drive the full Settings screen from the backend:
 *   - theme_mode:      light | dark | system  (per-account theme preference)
 *   - notification_settings is already JSON; we use it for fine-grained channels
 *     (push.bookings, push.messages, push.promotions, email.*).
 *   - privacy_settings: JSON bag for share-profile, analytics opt-in, etc.
 *
 * The columns are nullable / defaulted so existing rows continue to work.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // SQLite doesn't ship an ENUM type — emulate with a string + constraint
            // at the app layer (validated in ProfileController).
            $table->string('theme_mode', 10)->default('system')->after('preferred_units');
            $table->json('privacy_settings')->nullable()->after('notification_settings');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['theme_mode', 'privacy_settings']);
        });
    }
};
