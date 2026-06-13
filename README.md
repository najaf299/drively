# Drivly

Peer-to-Peer Car Rental Platform

## Overview

Drivly is a peer-to-peer car rental marketplace — similar to Getaround/Turo — built
for local and regional markets. The platform is two halves of one product:

- **Flutter mobile app** (iOS + Android) — serves both the **customer** (rent a car)
  and **host** (list & manage cars) experiences from a single codebase.
- **Laravel API + admin** — a single backend that powers the app and exposes a
  FilamentPHP admin console for operators.

## Tech Stack

### Backend (`backend/`)
- **Laravel 12** / **PHP 8.2+**
- **Laravel Sanctum** — token auth
- **FilamentPHP 3** — admin panel
- **Laravel Reverb** — WebSockets (real-time chat / presence)
- **Laravel Horizon** — Redis queue management
- **Stripe** (`stripe/stripe-php`) — payments & host payouts
- **Firebase** (`kreait/laravel-firebase`) — push notifications
- **Google API client** — Google sign-in verification
- **Spatie** — `laravel-medialibrary` (uploads), `laravel-permission` (roles),
  `laravel-activitylog` (audit)
- **Flysystem S3** — Cloudflare R2 / S3-compatible object storage
- **Pest 3 / PHPUnit 11** — test suite

### Frontend (`frontend/`)
- **Flutter** (Material 3)
- **Riverpod 2** (+ `riverpod_generator`) — state management
- **GoRouter** — navigation
- **Dio** — REST client
- **flutter_secure_storage** — token storage
- **google_maps_flutter** / **geolocator** / **geocoding** — maps & location
- **flutter_stripe** — in-app payments
- **google_sign_in** / **sign_in_with_apple** — social auth
- **web_socket_channel** — live chat transport
- **flutter_local_notifications** — local/push notifications
- **cached_network_image**, **shimmer**, **photo_view**, **flutter_rating_bar** — media/UX
- **fl_chart**, **table_calendar** — host analytics & availability
- **freezed** / **json_serializable** — immutable models & (de)serialization
- **hive_flutter** — local cache

### Databases & environments
- **Production target:** PostgreSQL (see `backend/.env.example` → `DB_CONNECTION=pgsql`),
  with **Redis** for queues/cache/broadcasting.
- **Local development:** the repo has been run against **MySQL** (`drivly` database).
  Any Laravel-supported driver works — set `DB_CONNECTION` in `.env`.
- **Tests:** run on **SQLite in-memory** (`phpunit.xml`), so no database server is
  required to run the suite.

### Target infrastructure (free-first)
- DigitalOcean Droplet · Cloudflare R2 (storage) · Firebase FCM (push) ·
  Let's Encrypt (SSL) · GitHub Actions (CI/CD)

## Key Features

- Car listing and search with map view, quick-filter pills, and a typed sort sheet
- Instant and request-based bookings
- Stripe payments with Connect-style payouts for hosts (demo mode works without keys)
- Real-time chat over WebSockets
- Pre/post-trip vehicle inspections with photo documentation
- Image uploads for car listings, KYC documents, and chat photos via a generic
  `POST /uploads` endpoint that returns a stored URL
- KYC verification for drivers
- In-app wallet (top-up, balance, transactions)
- Server-backed user settings (language, currency, distance units, theme, privacy,
  notification channels) — see "Settings" below
- Admin dashboard with analytics

### Discover & search
- Lime-on-dark **brand icon** across every iOS size + Android density (shares the
  marketing-site mark).
- **Quick-filter pills** on home (Top rated · Cheapest · Electric · Family 5+ ·
  Hybrid) plus a leading **Sort** pill that opens a typed sort sheet.
- **Active-filter strip**: each active filter is a chip you tap to remove, list
  refreshes in place.
- Search screen: visible **sort segment** (Newest · Top rated · Price ↑/↓),
  persistent **recent searches** with per-row remove, and a Clear-all action.
- Filters sheet adds a **year range** alongside price/seats/transmission/fuel.

### Settings (server-backed)
- `GET/PUT /settings` (`SettingsController`) is the single source of truth for
  language, currency, distance units, theme mode, push/email/SMS channels, and a
  privacy bag (`share_profile_with_hosts`, `analytics_opt_in`,
  `crash_reports_opt_in`, `marketing_opt_in`, `location_precision`).
- Migration `2026_05_30_000001_add_app_preferences_to_users` adds `theme_mode`
  (`light|dark|system`) and `privacy_settings` JSON to the users table.
- The Settings screen is fully wired — every toggle/picker PUTs through
  `SettingsService`; the local theme controller mirrors `theme_mode` so cold starts
  paint in the chosen mode; and it exposes **Sign out of all devices**
  (`POST /settings/sign-out-all`) and **Delete account** (`DELETE /account`,
  password-confirmed). Currency symbol and distance units are applied app-wide via
  `Formatters`.

## Project structure

```
drivly/
├── backend/                 # Laravel 12 API + Filament admin
│   ├── app/Http/Controllers # Customer/, Host/, Chat/, Admin/
│   ├── app/Models           # Car, Trip, User, ...
│   ├── app/Services         # ChatService, HostService, ...
│   ├── database/migrations  # schema (run in timestamp order)
│   ├── routes/api.php        # ~90 API routes
│   └── tests/Feature        # Pest/PHPUnit feature tests
└── frontend/                # Flutter app (customer + host)
    └── lib/
        ├── app/             # router, theme, app shell
        ├── core/            # network, models, utils, constants
        └── features/        # auth · booking · chat · discovery ·
                             #   host · profile · trip · wallet
```

## Getting Started

### Prerequisites
- PHP 8.2+, Composer
- A database (PostgreSQL or MySQL) and Redis — or just SQLite for a quick local spin
- Flutter SDK (stable channel)

### Backend
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
# Set DB_CONNECTION/DB_* in .env to your local DB (pgsql or mysql)
php artisan migrate --seed
php artisan serve            # http://127.0.0.1:8000
```
For real-time chat and queues during development:
```bash
php artisan reverb:start     # WebSocket server
php artisan horizon          # queue worker (requires Redis)
```

### Frontend
```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen (freezed/json/riverpod)
flutter run
```
Point the app at your API with `--dart-define=API_URL=...` (the base URL resolves
in `lib/core/constants/app_config.dart`). Convenience scripts wire this for you:
- `run_sim.sh` — iOS simulator
- `run_phone.sh` / `run_phone_debug.sh` — physical device over LAN

### Running tests
```bash
# Backend (SQLite in-memory — no DB server needed)
cd backend && php artisan test

# Frontend static analysis
cd frontend && flutter analyze
```

## Status / not-yet-final

The app is feature-complete for demo purposes. The following are intentional stubs
or dependent follow-ups (they work or degrade gracefully, but are not production-final):

- **Multi-language translation** — language is *persisted* and `MaterialApp.locale`
  is set, but UI strings are English-only for now. Currency symbol and distance
  units **are** applied. Full string translation (incl. Arabic RTL) is the dependent
  follow-up.
- **Apple / Google sign-in** — wired in the app; production requires real OAuth
  credentials. Demo tokens work in demo mode.
- **Stripe & Firebase** — run in demo mode without keys; production needs real
  Stripe/Firebase configuration.
- **Maps** — the browse map renders a styled canvas; live Google Maps tiles
  require a Google Maps API key.
- **Chat voice messages** — placeholder; text chat and **photo attachments**
  (gallery/camera) are live.

## Documentation

This README is the single source of truth for setup and architecture. The live
API surface is defined in `backend/routes/api.php` (~90 routes across Customer,
Host, Chat, and Admin), and the FilamentPHP admin console is served at `/admin`.

## License

Confidential — All rights reserved.
