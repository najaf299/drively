<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\SocialAuthController;
use App\Http\Controllers\Auth\OtpController;
use App\Http\Controllers\Customer\CarController;
use App\Http\Controllers\Customer\BookingController;
use App\Http\Controllers\Customer\FavoriteController;
use App\Http\Controllers\Customer\ProfileController;
use App\Http\Controllers\Host\CarManagementController;
use App\Http\Controllers\Host\EarningController;
use App\Http\Controllers\Host\BookingManagementController;
use App\Http\Controllers\Chat\ChatController;
use App\Http\Controllers\KYC\KycController;
use App\Http\Controllers\Admin\DashboardController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // Public Auth Routes
    Route::prefix('auth')->group(function () {
        Route::post('register', [RegisterController::class, 'register']);
        Route::post('login', [LoginController::class, 'login']);
        Route::post('google', [SocialAuthController::class, 'google']);
        Route::post('apple', [SocialAuthController::class, 'apple']);
        Route::post('otp/send', [OtpController::class, 'sendOtp']);
        Route::post('otp/verify', [OtpController::class, 'verifyOtp']);
    });

    // Public Car Browsing
    Route::get('cars', [CarController::class, 'index']);
    Route::get('cars/{car}', [CarController::class, 'show']);

    // Authenticated Routes
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::post('auth/logout', [LoginController::class, 'logout']);

        // Profile
        Route::get('profile', [ProfileController::class, 'show']);
        Route::put('profile', [ProfileController::class, 'update']);

        // KYC
        Route::get('kyc/status', [KycController::class, 'status']);
        Route::post('kyc/submit', [KycController::class, 'submit']);

        // Customer Routes
        Route::prefix('customer')->group(function () {
            Route::get('bookings', [BookingController::class, 'index']);
            Route::post('bookings', [BookingController::class, 'store']);
            Route::get('bookings/{booking}', [BookingController::class, 'show']);
            Route::post('bookings/{booking}/cancel', [BookingController::class, 'cancel']);
            Route::get('favorites', [FavoriteController::class, 'index']);
            Route::post('favorites/toggle', [FavoriteController::class, 'toggle']);
        });

        // Host Routes
        Route::prefix('host')->middleware('verified.host')->group(function () {
            Route::get('cars', [CarManagementController::class, 'index']);
            Route::post('cars', [CarManagementController::class, 'store']);
            Route::put('cars/{car}', [CarManagementController::class, 'update']);
            Route::delete('cars/{car}', [CarManagementController::class, 'destroy']);
            Route::get('bookings', [BookingManagementController::class, 'index']);
            Route::post('bookings/{booking}/approve', [BookingManagementController::class, 'approve']);
            Route::post('bookings/{booking}/decline', [BookingManagementController::class, 'decline']);
            Route::get('earnings', [EarningController::class, 'index']);
        });

        // Chat
        Route::prefix('chat')->group(function () {
            Route::get('threads', [ChatController::class, 'threads']);
            Route::get('threads/{thread}/messages', [ChatController::class, 'messages']);
            Route::post('messages', [ChatController::class, 'send']);
        });

        // Admin Routes
        Route::prefix('admin')->middleware('role:admin')->group(function () {
            Route::get('dashboard', [DashboardController::class, 'index']);
        });
    });
});
