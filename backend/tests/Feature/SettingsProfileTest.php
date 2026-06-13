<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

it('persists a bio through PUT /profile', function () {
    $user = User::factory()->create(['role' => 'customer']);

    $res = $this->actingAs($user)->putJson('/api/v1/profile', [
        'name' => 'Road Tripper',
        'bio' => 'Coffee and coastal drives.',
    ]);

    $res->assertOk();
    $this->assertDatabaseHas('users', [
        'id' => $user->id,
        'bio' => 'Coffee and coastal drives.',
    ]);
});

it('returns the full settings bundle with defaults merged', function () {
    $user = User::factory()->create(['role' => 'customer']);

    $res = $this->actingAs($user)->getJson('/api/v1/settings');

    $res->assertOk();
    expect($res->json('data.preferred_language'))->toBe('en');
    expect($res->json('data.notification_settings.push.bookings'))->toBeTrue();
    expect($res->json('data.privacy_settings.location_precision'))->toBe('precise');
});

it('persists scalar preferences via PUT /settings', function () {
    $user = User::factory()->create(['role' => 'customer']);

    $res = $this->actingAs($user)->putJson('/api/v1/settings', [
        'preferred_currency' => 'AED',
        'preferred_units' => 'mi',
        'theme_mode' => 'dark',
    ]);

    $res->assertOk();
    expect($res->json('data.preferred_currency'))->toBe('AED');
    expect($res->json('data.preferred_units'))->toBe('mi');
    expect($res->json('data.theme_mode'))->toBe('dark');
});

it('turns a notification channel OFF and keeps it off (deep merge preserves false)', function () {
    $user = User::factory()->create(['role' => 'customer']);

    // Toggle one key off; the rest of the bag must survive untouched.
    $res = $this->actingAs($user)->putJson('/api/v1/settings', [
        'notification_settings' => ['push' => ['bookings' => false]],
    ]);

    $res->assertOk();
    expect($res->json('data.notification_settings.push.bookings'))->toBeFalse();
    // A sibling default stays true (proves a partial patch doesn't nuke others).
    expect($res->json('data.notification_settings.push.messages'))->toBeTrue();

    // Re-fetch: the false value is durable, not reset by the defaults merge.
    $again = $this->actingAs($user)->getJson('/api/v1/settings');
    expect($again->json('data.notification_settings.push.bookings'))->toBeFalse();
});

it('updates a single privacy flag without dropping the others', function () {
    $user = User::factory()->create(['role' => 'customer']);

    $res = $this->actingAs($user)->putJson('/api/v1/settings', [
        'privacy_settings' => ['marketing_opt_in' => true],
    ]);

    $res->assertOk();
    expect($res->json('data.privacy_settings.marketing_opt_in'))->toBeTrue();
    expect($res->json('data.privacy_settings.analytics_opt_in'))->toBeTrue();
});
