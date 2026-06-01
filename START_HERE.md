# Drivly — Your Setup & Run Guide (read me first)

This is the only doc you need. It explains **what you have**, how to **run it**, and
how to **check** the customer/host phone app and the admin web panel.

---

## 0) What you have

| Part | Folder | What it is | How you open it |
| --- | --- | --- | --- |
| **Backend API** | `backend/` | Laravel API the apps talk to | runs at `http://localhost:8000` |
| **Admin panel** | `backend/` (Filament) | Web dashboard for staff | browser → `http://localhost:8000/admin` |
| **Mobile app** | `frontend/` | One Flutter app = renter **and** host | iPhone or Android |

There is **no separate admin app** — admin is a web page served by the backend.

> Project lives in `~/Downloads/Drively.` — note the **dot at the end** of the folder name.

---

## 1) Install the tools (one time)

- **PHP 8.3+** and **Composer** → https://getcomposer.org/download
- **Flutter** → https://docs.flutter.dev/get-started/install/macos  (then run `flutter doctor`)
- **For iPhone:** **Xcode** (Mac App Store) → then run `sudo xcodebuild -license accept` and `xcode-select --install`
- **For Android:** **Android Studio** → https://developer.android.com/studio (install an emulator from Device Manager)

Database/cache: the **easiest** option below uses **SQLite + no Redis**, so you don't have to install Postgres or Redis to test. (Production uses PostgreSQL + Redis.)

---

## 2) Run the backend (API + admin)

```bash
cd ~/Downloads/Drively./backend

composer install
cp .env.example .env
php artisan key:generate
```

### Easiest local config (no Postgres, no Redis)
Open `backend/.env` and change these lines so you can run with zero extra services:

```env
DB_CONNECTION=sqlite
# delete or comment out DB_HOST / DB_PORT / DB_DATABASE / DB_USERNAME / DB_PASSWORD

CACHE_STORE=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
BROADCAST_CONNECTION=log
```

Create the SQLite file, then build the database with demo data:

```bash
touch database/database.sqlite
php artisan migrate:fresh --seed
```

Enable the admin panel (one time — it isn't wired yet), then start the server:

```bash
php artisan filament:install --panels   # press Enter to accept defaults; creates the /admin panel
php artisan serve                        # API + admin now live at http://localhost:8000
```

Leave that terminal running.

> **Testing on a real iPhone?** Use `composer serve:lan` (or
> `php artisan serve --host=0.0.0.0`) so the phone can reach your Mac over Wi‑Fi.
> Plain `php artisan serve` only listens on `127.0.0.1` and will cause login timeouts.

> **Want realtime chat/live-trip too?** In a *second* terminal run `php artisan reverb:start`
> and in the `.env` set `BROADCAST_CONNECTION=reverb`. This is **optional** — the app works without it.

### Demo logins (created by the seeder, password is `password` for all)

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@drivly.com` | `password` |
| Host | `ahmed@drivly.com` | `password` |
| Customer | `john@example.com` | `password` |

---

## 3) Check the **admin panel**

1. Make sure `php artisan serve` is running (step 2).
2. Open a browser → **http://localhost:8000/admin**
3. Log in with **admin@drivly.com / password**.
4. You'll see Users, Cars, Bookings, Disputes, Promo codes.

---

## 4) Run the **mobile app** (renter + host)

```bash
cd ~/Downloads/Drively./frontend
flutter pub get
```

Pick the device you want below. Log in inside the app with **john@example.com / password**
(renter) or **ahmed@drivly.com / password** (host) — or tap **Sign up** to make a new account.

### A) iPhone — Simulator (easiest on Mac)
```bash
open -a Simulator
flutter run --dart-define=API_URL=http://localhost:8000/api/v1 --dart-define=WS_HOST=localhost
```

### B) iPhone — your real phone (USB or wireless)
1. Plug in the iPhone (or pair wirelessly), open `frontend/ios/Runner.xcworkspace` in **Xcode**
   once, set your Apple ID under **Signing & Team**, and **Trust** the computer on the phone.
2. Mac and iPhone must be on the **same Wi‑Fi**.
3. Start the API so the phone can reach it:
```bash
cd backend
composer serve:lan    # same as: php artisan serve --host=0.0.0.0
```
4. Install the app with the correct API URL (auto-detects your Mac IP every run):
```bash
cd frontend
./run_phone.sh
```
Optional: open `http://<your-mac-ip>:8000` in **Safari on the iPhone** before logging in to
confirm the API is reachable.

### Hot reload & debug (where it works)

| Device | Command | Hot reload (`r`) | Why |
| --- | --- | --- | --- |
| **iOS Simulator** | `cd frontend && ./run_sim.sh` | Yes | Same Wi‑Fi not needed; API = `localhost` |
| **Physical iPhone** | `./run_phone.sh` | No (release build) | Xcode 15.2 cannot attach to **iOS 26** phones |
| **Physical iPhone (try debug)** | `./run_phone_debug.sh` | Maybe | Only works after upgrading to **Xcode 16+** on this Mac |

After code changes on a **physical iPhone**, run `./run_phone.sh` again (full rebuild, ~5–10 min).
For day‑to‑day UI work, use the **simulator** with `./run_sim.sh` and press **`r`** in the terminal.

### C) Android — Emulator (easiest)
Start an emulator from Android Studio, then just:
```bash
flutter run
```
The default already points to `10.0.2.2` (the emulator's name for your Mac), so no flags needed.

### D) Android — your real phone (USB)
Enable **Developer options → USB debugging**, plug in, run the API with
`php artisan serve --host=0.0.0.0`, then:
```bash
flutter run \
  --dart-define=API_URL=http://192.168.1.20:8000/api/v1 \
  --dart-define=WS_HOST=192.168.1.20
```

---

## 5) Optional keys (only if you want these features)

The app **runs fully without any of these**. Add them later for real maps/payments/etc.
Put backend keys in `backend/.env`; pass the Flutter one with `--dart-define`.

| Feature | Where to get it | Where it goes |
| --- | --- | --- |
| **Stripe** (card payments) | https://dashboard.stripe.com/test/apikeys | `STRIPE_KEY`, `STRIPE_SECRET` in `backend/.env`; publishable key → Flutter `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...` |
| **Google Maps** (real map) | https://console.cloud.google.com/google/maps-apis | Android: `frontend/android/app/src/main/AndroidManifest.xml`; iOS: `frontend/ios/Runner/AppDelegate.swift` |
| **Google Sign-In** | https://console.cloud.google.com/apis/credentials | `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` in `backend/.env` + platform config |
| **Push notifications (Firebase)** | https://console.firebase.google.com | add `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) |
| **Apple Sign-In** | https://developer.apple.com/account → Identifiers | Xcode → Signing & Capabilities → add "Sign in with Apple" |

---

## 6) Quick troubleshooting

- **App can't reach the server / "No internet connection"** → your `API_URL` is wrong.
  Simulator/emulator: use the values in step 4. Real phone: use your Mac's IP **and**
  start the backend with `php artisan serve --host=0.0.0.0`. Phone and Mac must be on the same Wi‑Fi.
- **`/admin` shows "404 / not found"** → you skipped `php artisan filament:install --panels`.
- **Login fails** → run `php artisan migrate:fresh --seed` again to recreate demo users.
- **Flutter issues** → `flutter doctor` (fix anything red), then `flutter clean && flutter pub get`.
- **Health checks** → `flutter analyze` (should say *No issues found*), `php artisan route:list`.

---

## 7) Where the code is (quick map)

- `frontend/lib/features/<feature>/` — each feature has `data/` (API calls),
  `domain/` (state providers) and `presentation/screens/` (the UI).
- `frontend/lib/core/` — networking, models, theme, config.
- `frontend/lib/app/router.dart` — every screen + which URL opens it.
- `backend/routes/api.php` — all API endpoints. `backend/app/Filament/` — admin screens.
