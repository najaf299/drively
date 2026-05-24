<?php

use App\Models\Booking;
use App\Models\Car;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

/** Builds the well-formed (unsigned) JWT the app's demo OAuth sends. */
function demoToken(array $payload): string
{
    $seg = fn (array $m) => base64_encode(json_encode($m));

    return $seg(['alg' => 'none', 'typ' => 'JWT']) . '.' . $seg($payload) . '.demo';
}

it('signs in with a demo Google token and creates the account', function () {
    // Exercise the dev/demo decode path (no live cert fetch).
    config(['services.google.client_id' => null]);

    $token = demoToken([
        'sub' => 'google-demo-001',
        'email' => 'demo.google@drivly.io',
        'name' => 'Demo Driver',
    ]);

    $res = $this->postJson('/api/v1/auth/google', [
        'id_token' => $token,
        'name' => 'Demo Driver',
        'email' => 'demo.google@drivly.io',
    ]);

    $res->assertOk();
    expect($res->json('data.token'))->not->toBeEmpty();
    $this->assertDatabaseHas('users', ['email' => 'demo.google@drivly.io']);
});

it('signs in with a demo Apple token (with authorization_code)', function () {
    $token = demoToken(['sub' => 'apple-demo-001', 'email' => 'demo.apple@drivly.io']);

    $res = $this->postJson('/api/v1/auth/apple', [
        'identity_token' => $token,
        'authorization_code' => 'demo-apple-auth-code',
        'name' => 'Demo Apple User',
        'email' => 'demo.apple@drivly.io',
    ]);

    $res->assertOk();
    $this->assertDatabaseHas('users', ['email' => 'demo.apple@drivly.io']);
});

it('completes a booking payment in demo mode without Stripe keys', function () {
    config(['services.stripe.secret' => null]);

    $host = User::factory()->create(['role' => 'host']);
    $customer = User::factory()->create(['role' => 'customer']);
    $car = Car::factory()->create(['host_id' => $host->id]);

    $booking = Booking::factory()->create([
        'customer_id' => $customer->id,
        'car_id' => $car->id,
        'status' => 'pending',
        'total_amount' => 250.00,
    ]);

    $res = $this->actingAs($customer)->postJson("/api/v1/customer/bookings/{$booking->id}/pay");

    $res->assertOk();
    expect($res->json('data.demo'))->toBeTrue();
    $this->assertDatabaseHas('payments', [
        'booking_id' => $booking->id,
        'status' => 'succeeded',
    ]);
    expect($booking->fresh()->status->value ?? $booking->fresh()->status)->toBe('confirmed');
});

it('tops up the wallet balance', function () {
    $user = User::factory()->create(['role' => 'customer']);

    $res = $this->actingAs($user)->postJson('/api/v1/customer/wallet/top-up', [
        'amount' => 50,
    ]);

    $res->assertCreated();
    expect((float) $res->json('data.new_balance'))->toBe(50.0);
});

it('rejects a wallet top-up below the minimum', function () {
    $user = User::factory()->create(['role' => 'customer']);

    $this->actingAs($user)
        ->postJson('/api/v1/customer/wallet/top-up', ['amount' => 1])
        ->assertStatus(422);
});
