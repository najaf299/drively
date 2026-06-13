# Drivly — Backend (Laravel API)

The Laravel 12 API and FilamentPHP admin console for the Drivly peer-to-peer car
rental platform. Powers the Flutter app (customer + host) and operator admin.

For the full project overview, stack, and project structure, see the
[root README](../README.md).

## Stack
- Laravel 12 / PHP 8.2+
- Sanctum (token auth) · Filament 3 (admin) · Reverb (WebSockets) · Horizon (queues)
- Stripe (payments/payouts) · Firebase (push) · Spatie media-library/permission/activitylog
- Storage via Flysystem S3 (Cloudflare R2 / S3-compatible)

## Local setup
```bash
composer install
cp .env.example .env
php artisan key:generate
# Configure DB_CONNECTION/DB_* in .env (pgsql in .env.example; mysql also supported)
php artisan migrate --seed
php artisan serve            # http://127.0.0.1:8000
```

Optional dev services:
```bash
php artisan reverb:start     # WebSocket server (real-time chat)
php artisan horizon          # queue worker (requires Redis)
```

## Tests
```bash
php artisan test             # Pest/PHPUnit, runs on SQLite in-memory (no DB server needed)
```

## Layout
- `app/Http/Controllers` — grouped by audience: `Customer/`, `Host/`, `Chat/`, `Admin/`
- `app/Models` — Eloquent models (Car, Trip, User, …)
- `app/Services` — domain services (ChatService, HostService, …)
- `database/migrations` — schema (apply in timestamp order)
- `routes/api.php` — ~90 API routes (Sanctum-protected where applicable)

## License
Confidential — All rights reserved.
