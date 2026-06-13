<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

it('uploads an image and returns a reachable URL', function () {
    Storage::fake('public');
    $user = User::factory()->create();

    $res = $this->actingAs($user)->postJson('/api/v1/uploads', [
        'file' => UploadedFile::fake()->image('photo.jpg', 800, 600),
        'folder' => 'car_photos',
    ]);

    $res->assertCreated();
    expect($res->json('data.url'))->toContain('/storage/car_photos/');

    // The file actually landed on the public disk.
    $stored = str(parse_url($res->json('data.url'), PHP_URL_PATH))->after('/storage/');
    Storage::disk('public')->assertExists((string) $stored);
});

it('falls back to the misc folder for an unknown folder', function () {
    Storage::fake('public');
    $user = User::factory()->create();

    $res = $this->actingAs($user)->postJson('/api/v1/uploads', [
        'file' => UploadedFile::fake()->image('photo.png'),
        'folder' => 'hax../../etc',
    ]);

    $res->assertCreated();
    expect($res->json('data.url'))->toContain('/storage/misc/');
});

it('rejects a non-image upload', function () {
    Storage::fake('public');
    $user = User::factory()->create();

    $res = $this->actingAs($user)->postJson('/api/v1/uploads', [
        'file' => UploadedFile::fake()->create('virus.pdf', 100, 'application/pdf'),
    ]);

    $res->assertStatus(422);
});

it('requires authentication', function () {
    $res = $this->postJson('/api/v1/uploads', [
        'file' => UploadedFile::fake()->image('photo.jpg'),
    ]);

    $res->assertUnauthorized();
});
