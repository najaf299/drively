# Drivly — Run & Demo Guide

Quick guide to run the app (simulator + physical iPhone) and the backend, plus the
gotchas specific to this machine.

## TL;DR — start everything

```bash
# 1. Backend (Laravel + MySQL via XAMPP). MySQL must be running.
cd "/Users/app/Desktop/Drively./backend"
php artisan serve --host=0.0.0.0 --port=8000        # keep this running

# 2a. App on the iOS simulator (debug + hot reload)
cd "/Users/app/Desktop/Drively./frontend"
open -a Simulator
flutter run -d <simulator-id>                        # r = hot reload

# 2b. App on the physical iPhone (RELEASE — see "Why release" below)
flutter build ios --release
xcrun devicectl device install app  --device 00008110-00111DE43C89A01E build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --terminate-existing --device 00008110-00111DE43C89A01E com.najafali.drivly
# (iPhone must be unlocked to launch.)
```

## Demo logins (seeded, password = `password`)

| Role     | Email               |
|----------|---------------------|
| Customer | `john@example.com`  |
| Host     | `ahmed@drivly.com`  |
| Admin    | `admin@drivly.com`  |

## Backend (MySQL)

- DB config lives in `backend/.env` (not committed): `DB_CONNECTION=mysql`,
  host `127.0.0.1:3306`, database `drivly`, user `root`, empty password (XAMPP).
- Cache/session/queue set to `file`/`sync` and broadcast to `log` so it runs
  without Redis/Reverb.
- Reset / reseed the database:
  ```bash
  php artisan migrate:fresh --seed --force
  ```

## Connectivity

- The app's API base URL is the Mac's LAN IP: `http://192.168.100.8:8000/api/v1`
  (in `frontend/lib/core/constants/app_config.dart`). This works on **both** the
  simulator and the iPhone **as long as both are on the same Wi-Fi**.
- If the Wi-Fi/IP changes, update `apiBaseUrl` (and `wsHost`) or pass
  `--dart-define=API_URL=http://<new-ip>:8000/api/v1`.
- iOS would normally block plain HTTP; an App Transport Security exception is set
  in `frontend/ios/Runner/Info.plist` (dev only — use HTTPS in production).

## Why "release" on the iPhone

This Mac has **Xcode 15.2** (supports iOS ≤ 17.2) but the iPhone runs **iOS 26**.
The debugger can't attach across that gap, so:

- **iPhone → release builds only** (no hot reload). Install/launch via `devicectl`
  (works on iOS 26). Tapping the home-screen icon also works.
- **Hot reload / debugging → use the iOS 17.2 simulator.**
- Free personal signing team `7TN8ZZK66L`, bundle id `com.najafali.drivly`.
  The free signature **expires ~7 days** → rebuild + reinstall to refresh.
- Long-term fix: update macOS (Sonoma+) and Xcode (16+), or use a newer Mac.

## Troubleshooting

- **Login does nothing / network error** → backend not running, or phone/Mac on
  different Wi-Fi, or the LAN IP changed. Check `php artisan serve` is up and the
  IP in `app_config.dart`.
- **App white-screens then closes on the phone** → was caused by missing iOS
  privacy usage strings (now added in `Info.plist`).
- **Simulator won't boot (`launchd_sim`)** → `killall -9 com.apple.CoreSimulator.CoreSimulatorService` then reopen Simulator.
- **Build hangs at "Running Xcode build" with no progress** → a stuck `ibtoold`;
  `killall -9 ibtoold` and re-run.

## What's implemented

- Auth: onboarding, sign in, sign up (3 steps: account → OTP → license KYC).
- Discovery: home, search, filters, map, car detail.
  - Branded app icon (lime-on-dark car mark, generated from the backend
    favicon — replaces the default Flutter logo on iOS + Android).
  - Quick-filter pills + Sort pill on the home page, active-filter strip
    with one-tap remove, year-range slider in the filter sheet.
  - Search screen has a visible sort segment, persistent recent-searches
    list, and per-row remove.
- Booking: confirm trip, success, date/time.
- Trips: my trips, active trip, reviews, chat with host.
- Wallet & profile: wallet, payment methods, profile, settings, notifications.
- **Full Settings, backend-driven** — language, currency, units, theme
  (light/dark/system), push + email + SMS channels, privacy toggles
  (share-profile, analytics, crash reports, marketing, location precision).
  Backed by `GET/PUT /settings`, plus *Sign out of all devices* and
  *Delete account* security actions.
- Host: become a host, list a car + smart pricing, dashboards.

## Backend settings endpoints (new)

| Method | Path                       | Purpose |
|--------|----------------------------|---------|
| GET    | `/settings`                | Full bundle (prefs, notifications, privacy) |
| PUT    | `/settings`                | Partial update — JSON bags merge server-side |
| POST   | `/settings/sign-out-all`   | Revokes every Sanctum token for this user |
| DELETE | `/account`                 | Soft-deletes the account (password-confirmed) |

The `users` table gained two columns via the
`2026_05_30_000001_add_app_preferences_to_users` migration:

- `theme_mode` (`light` | `dark` | `system`)
- `privacy_settings` (JSON bag)
