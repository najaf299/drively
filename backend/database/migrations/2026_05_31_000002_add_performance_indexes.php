<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Performance indexes for the hottest filter/sort paths.
 *
 * Laravel's foreignUuid()->constrained() already indexes the bare FK columns,
 * so these target the real gaps surfaced by the query audit: status filters,
 * the (FK + created_at) combos used for "list mine, newest first", and the
 * public car-browse sort columns.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cars', function (Blueprint $table) {
            // Public `GET /cars` always filters status='active'; the existing
            // composite leads with `city`, so a status-only browse can't use it.
            $table->index('status', 'cars_status_index');
            // Cover the two price/rating sorts applied on top of the status filter.
            $table->index(['status', 'daily_price'], 'cars_status_price_index');
            $table->index(['status', 'average_rating'], 'cars_status_rating_index');
        });

        Schema::table('earnings', function (Blueprint $table) {
            // Host earnings history + monthly summary: where host_id, order by created_at.
            $table->index(['host_id', 'created_at'], 'earnings_host_created_index');
        });

        Schema::table('wallet_transactions', function (Blueprint $table) {
            $table->index(['wallet_id', 'created_at'], 'wallet_tx_wallet_created_index');
        });

        Schema::table('kyc_documents', function (Blueprint $table) {
            // Admin review queue: where status='pending', order by created_at.
            $table->index(['status', 'created_at'], 'kyc_status_created_index');
        });

        Schema::table('disputes', function (Blueprint $table) {
            // Admin queue filters by status; customer list filters reporter + newest.
            $table->index('status', 'disputes_status_index');
            $table->index(['reporter_id', 'created_at'], 'disputes_reporter_created_index');
        });

        Schema::table('reviews', function (Blueprint $table) {
            // Per-car public reviews, newest first (car detail + reviews list).
            $table->index(['car_id', 'is_public', 'created_at'], 'reviews_car_public_created_index');
            // "My reviews", newest first.
            $table->index(['reviewer_id', 'created_at'], 'reviews_reviewer_created_index');
        });

        Schema::table('bookings', function (Blueprint $table) {
            // Admin/host status filters + dashboard status counts, newest first.
            $table->index(['status', 'created_at'], 'bookings_status_created_index');
        });
    }

    public function down(): void
    {
        Schema::table('cars', function (Blueprint $table) {
            $table->dropIndex('cars_status_index');
            $table->dropIndex('cars_status_price_index');
            $table->dropIndex('cars_status_rating_index');
        });
        Schema::table('earnings', function (Blueprint $table) {
            $table->dropIndex('earnings_host_created_index');
        });
        Schema::table('wallet_transactions', function (Blueprint $table) {
            $table->dropIndex('wallet_tx_wallet_created_index');
        });
        Schema::table('kyc_documents', function (Blueprint $table) {
            $table->dropIndex('kyc_status_created_index');
        });
        Schema::table('disputes', function (Blueprint $table) {
            $table->dropIndex('disputes_status_index');
            $table->dropIndex('disputes_reporter_created_index');
        });
        Schema::table('reviews', function (Blueprint $table) {
            $table->dropIndex('reviews_car_public_created_index');
            $table->dropIndex('reviews_reviewer_created_index');
        });
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropIndex('bookings_status_created_index');
        });
    }
};
