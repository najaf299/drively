# Drivly

Peer-to-Peer Car Rental Platform

## Overview

Drivly is a peer-to-peer car rental marketplace — similar to Getaround — built for local and regional markets. The platform consists of three interconnected systems:

- **Customer mobile app** (iOS + Android)
- **Host mobile app** (iOS + Android)
- **Admin web console**

All three share a single Laravel API backend.

## Tech Stack

### Backend
- Laravel 12 / PHP 8.3
- PostgreSQL
- Redis
- FilamentPHP (Admin Panel)
- Laravel Sanctum (Auth)
- Laravel Reverb (WebSockets)
- Laravel Horizon (Queue Management)
- Stripe (Payments & Payouts)

### Frontend
- Flutter (Material 3)
- Riverpod 2 (State Management)
- GoRouter (Navigation)
- Dio + Retrofit (Networking)
- Firebase (Push Notifications, Analytics, Crashlytics)

### Infrastructure (Free-First)
- DigitalOcean Droplet ($24/month, 4 GB RAM)
- Cloudflare R2 (File Storage)
- Firebase FCM (Push Notifications)
- Let's Encrypt SSL
- GitHub Actions (CI/CD)

## Key Features

- Car listing and search with map view
- Instant and request-based bookings
- Stripe payment integration with Connect payouts for hosts
- Real-time chat via WebSockets
- Pre/post-trip vehicle inspections with photo documentation
- KYC verification for drivers
- In-app wallet system
- Multi-language support (English, Spanish, Arabic, French, German)
- Dynamic pricing suggestions
- Promo codes and referral system
- Admin dashboard with analytics

### Discover & search

- Lime-on-dark **brand icon** (replaces the default Flutter logo on every iOS
  size + every Android density). Generated from the backend landing-page
  favicon so the marketing site and app share one mark.
- **Quick-filter pills** on the home page (Top rated · Cheapest · Electric ·
  Family 5+ · Hybrid) plus a leading **Sort** pill that opens a typed sort
  sheet — no more misleading date-shaped chips that didn't actually pick a
  date.
- **Active-filter strip** on home: every active filter renders as a chip you
  can tap to remove (one tap == one filter cleared, with the result list
  refreshed in place).
- Search screen has a **visible sort segment** (Newest · Top rated · Price ↑ /
  ↓), persistent **recent searches** with per-row remove, and an explicit
  Clear-all action.
- Filters sheet adds a **year range** alongside price/seats/transmission/fuel.

### Full Settings, server-backed

- New `GET/PUT /settings` endpoint (`SettingsController`) is the single source
  of truth for: language, currency, distance units, theme mode, push/email/SMS
  channels, and privacy bag (`share_profile_with_hosts`,
  `analytics_opt_in`, `crash_reports_opt_in`, `marketing_opt_in`,
  `location_precision`).
- Migration `2026_05_30_000001_add_app_preferences_to_users` adds `theme_mode`
  (`light|dark|system`) and `privacy_settings` JSON to the users table.
- The mobile **Settings screen** is now fully wired — every toggle and picker
  PUTs through `SettingsService`, the local theme controller mirrors
  `theme_mode` so cold starts paint in the chosen mode immediately, and the
  screen exposes **Sign out of all devices** (`POST /settings/sign-out-all`)
  and **Delete account** (`DELETE /account`, password-confirmed).
- Lower-noise UX: removed `Coming soon` toasts in the Profile menu (Language
  now jumps to Settings) and the Active Trip card (Photos → booking detail,
  Support → Help center).

## Documentation

See `drivly_complete_build_spec.docx` for the complete build specification including:
- Full database schema (34 tables)
- 60+ API endpoint contracts
- 34 screen specifications
- Flutter app architecture
- Deployment and infrastructure setup
- Security checklist
- Payment integration details

## Getting Started

Refer to the build specification document for detailed setup instructions.

### Backend Setup
```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### Flutter Setup
```bash
flutter pub get
flutter run
```

## License

Confidential - All rights reserved.
