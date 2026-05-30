<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\SocialAuthController;
use App\Http\Controllers\Auth\OtpController;
use App\Http\Controllers\Auth\PasswordResetController;
use App\Http\Controllers\Customer\CarController;
use App\Http\Controllers\Customer\BookingController;
use App\Http\Controllers\Customer\FavoriteController;
use App\Http\Controllers\Customer\ProfileController;
use App\Http\Controllers\Customer\TripController;
use App\Http\Controllers\Customer\ReviewController;
use App\Http\Controllers\Customer\WalletController;
use App\Http\Controllers\Customer\NotificationController;
use App\Http\Controllers\Customer\SettingsController;
use App\Http\Controllers\Customer\DisputeController;
use App\Http\Controllers\Host\CarManagementController;
use App\Http\Controllers\Host\EarningController;
use App\Http\Controllers\Host\BookingManagementController;
use App\Http\Controllers\Host\VerificationController;
use App\Http\Controllers\Chat\ChatController;
use App\Http\Controllers\KYC\KycController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\UserManagementController;
use App\Http\Controllers\Admin\CarManagementController as AdminCarController;
use App\Http\Controllers\Admin\KycManagementController;
use App\Http\Controllers\Admin\DisputeManagementController;
use App\Http\Controllers\Admin\PromoCodeController;
use App\Http\Controllers\Webhook\StripeWebhookController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Webhooks (no auth)
Route::post('webhooks/stripe', [StripeWebhookController::class, 'handle']);

Route::prefix('v1')->group(function () {

    // ── Public Auth Routes ──
    Route::prefix('auth')->group(function () {
        Route::post('register', [RegisterController::class, 'register']);
        Route::post('login', [LoginController::class, 'login']);
        Route::post('google', [SocialAuthController::class, 'google']);
        Route::post('apple', [SocialAuthController::class, 'apple']);
        Route::post('otp/send', [OtpController::class, 'sendOtp']);
        Route::post('otp/verify', [OtpController::class, 'verifyOtp']);
        Route::post('forgot-password', [PasswordResetController::class, 'forgotPassword']);
        Route::post('reset-password', [PasswordResetController::class, 'resetPassword']);
    });

    // ── Public Car Browsing ──
    Route::get('cars', [CarController::class, 'index']);
    Route::get('cars/{car}', [CarController::class, 'show']);
    Route::get('cars/{car}/reviews', [ReviewController::class, 'carReviews']);

    // ── Authenticated Routes ──
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::post('auth/logout', [LoginController::class, 'logout']);

        // Profile
        Route::get('profile', [ProfileController::class, 'show']);
        Route::put('profile', [ProfileController::class, 'update']);
        Route::post('profile/avatar', [ProfileController::class, 'uploadAvatar']);
        Route::post('profile/password', [ProfileController::class, 'changePassword']);
        Route::delete('profile/linked/{provider}', [ProfileController::class, 'unlinkProvider']);

        // Settings (drives the full in-app Settings screen)
        Route::get('settings', [SettingsController::class, 'show']);
        Route::put('settings', [SettingsController::class, 'update']);
        Route::post('settings/sign-out-all', [SettingsController::class, 'logoutAllSessions']);
        Route::delete('account', [SettingsController::class, 'deleteAccount']);

        // KYC
        Route::prefix('kyc')->group(function () {
            Route::get('status', [KycController::class, 'status']);
            Route::post('submit', [KycController::class, 'submit']);
        });

        // ── Customer Routes ──
        Route::prefix('customer')->group(function () {
            // Bookings
            Route::get('bookings', [BookingController::class, 'index']);
            Route::post('bookings', [BookingController::class, 'store']);
            Route::post('bookings/pricing', [BookingController::class, 'pricing']);
            Route::get('bookings/{booking}', [BookingController::class, 'show']);
            Route::post('bookings/{booking}/cancel', [BookingController::class, 'cancel']);
            Route::post('bookings/{booking}/pay', [BookingController::class, 'pay']);
            Route::post('bookings/{booking}/payment/confirm', [BookingController::class, 'confirmPayment']);

            // Reviews
            Route::get('reviews', [ReviewController::class, 'myReviews']);
            Route::post('bookings/{booking}/review', [ReviewController::class, 'store']);

            // Trips
            Route::get('trips/{trip}', [TripController::class, 'show']);
            Route::post('bookings/{booking}/trip/start', [TripController::class, 'start']);
            Route::post('trips/{trip}/end', [TripController::class, 'end']);
            Route::post('trips/{trip}/location', [TripController::class, 'updateLocation']);
            Route::post('trips/{trip}/extend', [TripController::class, 'extend']);

            // Favorites
            Route::get('favorites', [FavoriteController::class, 'index']);
            Route::post('favorites/toggle', [FavoriteController::class, 'toggle']);

            // Wallet
            Route::get('wallet', [WalletController::class, 'show']);
            Route::get('wallet/transactions', [WalletController::class, 'transactions']);
            Route::post('wallet/top-up', [WalletController::class, 'topUp']);
            Route::post('wallet/withdraw', [WalletController::class, 'withdraw']);

            // Disputes
            Route::get('disputes', [DisputeController::class, 'index']);
            Route::post('bookings/{booking}/dispute', [DisputeController::class, 'store']);
            Route::get('disputes/{dispute}', [DisputeController::class, 'show']);
        });

        // ── Notifications ──
        Route::prefix('notifications')->group(function () {
            Route::get('/', [NotificationController::class, 'index']);
            Route::post('{id}/read', [NotificationController::class, 'markAsRead']);
            Route::post('read-all', [NotificationController::class, 'markAllRead']);
            Route::post('devices', [NotificationController::class, 'registerDevice']);
            Route::delete('devices', [NotificationController::class, 'unregisterDevice']);
        });

        // ── Host Routes ──
        Route::prefix('host')->group(function () {
            // Verification (before verified.host middleware)
            Route::get('verification/status', [VerificationController::class, 'status']);
            Route::post('verification/initiate', [VerificationController::class, 'initiate']);
            Route::post('verification/step', [VerificationController::class, 'updateStep']);
            Route::get('stats', [VerificationController::class, 'stats']);

            // Verified host routes
            Route::middleware('verified.host')->group(function () {
                Route::get('cars', [CarManagementController::class, 'index']);
                Route::post('cars', [CarManagementController::class, 'store']);
                Route::put('cars/{car}', [CarManagementController::class, 'update']);
                Route::delete('cars/{car}', [CarManagementController::class, 'destroy']);
                Route::post('cars/{car}/photos', [CarManagementController::class, 'addPhotos']);
                Route::delete('cars/{car}/photos/{photo}', [CarManagementController::class, 'deletePhoto']);
                Route::get('bookings', [BookingManagementController::class, 'index']);
                Route::post('bookings/{booking}/approve', [BookingManagementController::class, 'approve']);
                Route::post('bookings/{booking}/decline', [BookingManagementController::class, 'decline']);
                Route::get('earnings', [EarningController::class, 'index']);
                Route::get('earnings/history', [EarningController::class, 'history']);
            });
        });

        // ── Chat ──
        Route::prefix('chat')->group(function () {
            Route::get('threads', [ChatController::class, 'threads']);
            Route::get('threads/{thread}/messages', [ChatController::class, 'messages']);
            Route::post('messages', [ChatController::class, 'send']);
            Route::post('threads/{thread}/read', [ChatController::class, 'markAsRead']);
        });

        // ── Admin Routes ──
        Route::prefix('admin')->middleware('role:admin')->group(function () {
            Route::get('dashboard', [DashboardController::class, 'index']);

            // User management
            Route::get('users', [UserManagementController::class, 'index']);
            Route::get('users/{user}', [UserManagementController::class, 'show']);
            Route::post('users/{user}/suspend', [UserManagementController::class, 'suspend']);
            Route::post('users/{user}/unsuspend', [UserManagementController::class, 'unsuspend']);

            // Car management
            Route::get('cars', [AdminCarController::class, 'index']);
            Route::post('cars/{car}/approve', [AdminCarController::class, 'approve']);
            Route::post('cars/{car}/reject', [AdminCarController::class, 'reject']);
            Route::post('cars/{car}/suspend', [AdminCarController::class, 'suspend']);

            // KYC management
            Route::get('kyc/pending', [KycManagementController::class, 'pending']);
            Route::post('kyc/{document}/review', [KycManagementController::class, 'review']);

            // Dispute management
            Route::get('disputes', [DisputeManagementController::class, 'index']);
            Route::post('disputes/{dispute}/resolve', [DisputeManagementController::class, 'resolve']);
            Route::post('disputes/{dispute}/escalate', [DisputeManagementController::class, 'escalate']);

            // Promo codes
            Route::get('promo-codes', [PromoCodeController::class, 'index']);
            Route::post('promo-codes', [PromoCodeController::class, 'store']);
            Route::put('promo-codes/{promoCode}', [PromoCodeController::class, 'update']);
            Route::delete('promo-codes/{promoCode}', [PromoCodeController::class, 'destroy']);
        });
    });
});
