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
- Multi-language support (English, Spanish, Arabic)
- Dynamic pricing suggestions
- Promo codes and referral system
- Admin dashboard with analytics

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
