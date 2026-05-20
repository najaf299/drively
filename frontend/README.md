# Drivly — Flutter App

The Drivly customer + host mobile app (Flutter, Material 3), wired to the Laravel
API in [`../backend`](../backend). Renters can discover and book cars, run live
trips, chat, manage a wallet and review trips; hosts can verify, list cars,
manage bookings and track earnings.

> **Status:** the full data layer and navigation are implemented and the project
> passes `flutter analyze` with **no issues**. The core renter and host flows are
> wired end-to-end against the real API.

---

## 1. Quick start

```bash
cd frontend
flutter pub get

# Run against a locally-running backend (see ../backend/README.md).
# Android emulator → host machine is 10.0.2.2 (the default):
flutter run

# iOS simulator / macOS / web / Chrome → use localhost:
flutter run --dart-define=API_URL=http://localhost:8000/api/v1 \
            --dart-define=WS_HOST=localhost
```

The app talks to the backend over HTTP and (optionally) WebSockets. Make sure the
Laravel API is reachable at the configured `API_URL`.

### Configuration (`--dart-define`)

All environment configuration is compile-time (`lib/core/constants/app_config.dart`):

| Key | Default | Notes |
| --- | --- | --- |
| `API_URL` | `http://10.0.2.2:8000/api/v1` | REST base URL **including** `/api/v1` |
| `WS_HOST` | `10.0.2.2` | Laravel Reverb host |
| `WS_PORT` | `8080` | Reverb port |
| `WS_SCHEME` | `ws` | `ws` (local) or `wss` (TLS) |
| `REVERB_APP_KEY` | `drivly-key` | Must match backend `REVERB_APP_KEY` |
| `STRIPE_PUBLISHABLE_KEY` | _(empty)_ | Enables card payments when set |

`10.0.2.2` is the Android emulator's alias for the host machine's `localhost`.

---

## 2. Architecture

Feature-first, layered, with **Riverpod** for state and **GoRouter** for
navigation. Networking is **Dio**; models are hand-written (no codegen) and map
exactly to the backend's JSON resources.

```
lib/
├── app/                     # App shell
│   ├── app.dart             # Root MaterialApp.router (dark theme)
│   ├── router.dart          # GoRouter: routes, auth guard, bottom-nav shell
│   └── theme.dart           # Design system: BrandColors, Spacing, Radii, ThemeData
├── core/
│   ├── constants/           # app_config (env), api_endpoints
│   ├── errors/              # AppException (single user-facing error type)
│   ├── models/              # Plain Dart models w/ hand-written fromJson
│   ├── network/             # dio_client, auth_interceptor, api_response, realtime_client
│   ├── storage/             # secure_storage (tokens), local_cache (Hive)
│   └── utils/               # json_utils, formatters, validators
├── features/<feature>/
│   ├── data/                # *_service.dart  (typed API calls)
│   ├── domain/              # providers + value objects (filters, drafts)
│   └── presentation/        # screens
│       └── screens/
└── shared/widgets/          # CarCard, TripCard, StatusChip, state views, etc.
```

**Data flow:** `Screen → Provider → Service (Dio) → JSON → Model`. Every service
method wraps failures in a single `AppException` (`core/network/error_handler.dart`)
so the UI only ever deals with friendly messages; the `AsyncValueView` widget
renders loading / error (with retry) / data uniformly.

### Backend contract notes (handled in code)

- **Response envelope:** `{ success, message, data }` — unwrapped by `ApiResponse`.
- **Auth:** a single Sanctum token (`{ user, token }`) — no refresh token. Stored
  in `flutter_secure_storage`; injected by `AuthInterceptor`; a `401` clears the
  session and routes to sign-in.
- **Decimals as strings:** Postgres `decimal` columns serialise as strings
  (e.g. `"45.00"`, lat/lng); `core/utils/json_utils.dart` parses these safely.
- **Pagination is inconsistent:** resource collections come back as a bare array,
  raw paginators as `{ data: [...], current_page, ... }`. `Paginated.from`
  normalises both.

---

## 3. What's implemented

**Auth:** splash, onboarding, sign in (email + Google/Apple), sign up (role
toggle + password strength), phone OTP, KYC capture.

**Renter:** home/discovery (search, quick filters, infinite scroll), search,
filter sheet, map view, car detail (gallery, specs, host, reviews), date/time
picker, booking summary (pricing preview, add-ons, promo), booking success,
my trips (tabs), booking detail (start/cancel/call host), live trip
(countdown, end/extend, realtime), rate trip, reviews, wallet (balance + top-up
+ transactions), payment methods, notifications, profile, settings.

**Host:** verification wizard, dashboard, fleet list, add-car form, bookings
(accept/decline), earnings (period summary + history).

**Realtime:** `core/network/realtime_client.dart` connects to Laravel Reverb
(Pusher protocol) for chat and live-trip updates, with REST polling as a fallback
so the app works fully even when WebSockets are unavailable.

---

## 4. Known integration points / limitations

These require environment-specific credentials and degrade gracefully without them:

- **Stripe:** booking creates the reservation; the Payment Sheet activates once
  `STRIPE_PUBLISHABLE_KEY` is provided. Wallet top-up works today.
- **Google Maps:** the Map screen shows a results list; drop a `GoogleMap` widget
  in once a Maps API key is configured (see `map_screen.dart`).
- **Google / Apple sign-in:** wired; require platform OAuth configuration to
  complete (errors are caught and surfaced as a snackbar otherwise).
- **KYC / host docs upload:** capture is wired; uploading the captured images to
  object storage (Cloudflare R2) is an environment-specific media step, after
  which the resulting URLs are submitted via the existing endpoints.
- **Fonts:** uses the platform default with the design-system type scale. To match
  the spec exactly, add Space Grotesk / Inter `.ttf` files under `assets/fonts/`
  and re-declare them in `pubspec.yaml`.

---

## 5. Development

```bash
flutter analyze        # static analysis (currently: No issues found)
dart format lib        # formatting
flutter test           # tests
```

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for a deeper map of services ↔ endpoints.
