# Drivly Flutter — Architecture Reference

A map of the data layer (services ↔ API endpoints ↔ models) and the navigation
graph. Base URL: `{API_URL}` (default `http://10.0.2.2:8000/api/v1`).

## Layers

```
Screen (ConsumerWidget)
  → Provider (Riverpod: FutureProvider / StateNotifier)
    → Service (Dio wrapper, throws AppException)
      → ApiResponse.unwrap + Model.fromJson
```

## Services → Endpoints

### AuthService — `features/auth/data/auth_service.dart`
| Method | Endpoint |
| --- | --- |
| `register` | `POST /auth/register` |
| `login` | `POST /auth/login` |
| `loginWithGoogle` | `POST /auth/google` |
| `loginWithApple` | `POST /auth/apple` |
| `sendOtp` / `verifyOtp` | `POST /auth/otp/send` · `POST /auth/otp/verify` |
| `logout` | `POST /auth/logout` |
| `getProfile` / `updateProfile` | `GET` · `PUT /profile` |

### KycService — `features/auth/data/kyc_service.dart`
`GET /kyc/status` · `POST /kyc/submit`

### CarService — `features/discovery/data/car_service.dart`
`GET /cars` (filters) · `GET /cars/{id}` · `GET /cars/{id}/reviews`

### FavoriteService — `features/discovery/data/favorite_service.dart`
`GET /customer/favorites` · `POST /customer/favorites/toggle`

### BookingService — `features/booking/data/booking_service.dart`
`GET /customer/bookings` · `POST /customer/bookings` ·
`POST /customer/bookings/pricing` · `GET /customer/bookings/{id}` ·
`POST /customer/bookings/{id}/cancel` · `POST /customer/bookings/{id}/pay`

### TripService — `features/trip/data/trip_service.dart`
`GET /customer/trips/{id}` ·
`POST /customer/bookings/{id}/trip/start` ·
`POST /customer/trips/{id}/end` · `.../location` · `.../extend`

### ReviewService — `features/trip/data/review_service.dart`
`POST /customer/bookings/{id}/review` · `GET /customer/reviews`

### DisputeService — `features/trip/data/dispute_service.dart`
`GET /customer/disputes` · `POST /customer/bookings/{id}/dispute` ·
`GET /customer/disputes/{id}`

### WalletService — `features/wallet/data/wallet_service.dart`
`GET /customer/wallet` · `GET /customer/wallet/transactions` ·
`POST /customer/wallet/top-up`

### ChatService — `features/chat/data/chat_service.dart`
`GET /chat/threads` · `GET /chat/threads/{id}/messages` ·
`POST /chat/messages` · `POST /chat/threads/{id}/read`

### NotificationService — `features/profile/data/notification_service.dart`
`GET /notifications` · `POST /notifications/{id}/read` ·
`POST /notifications/read-all` · `POST|DELETE /notifications/devices`

### HostService — `features/host/data/host_service.dart`
`GET /host/verification/status` · `POST /host/verification/initiate` ·
`POST /host/verification/step` · `GET /host/stats` ·
`GET|POST /host/cars` · `PUT|DELETE /host/cars/{id}` · `POST /host/cars/{id}/photos` ·
`GET /host/bookings` · `POST /host/bookings/{id}/approve|decline` ·
`GET /host/earnings` · `GET /host/earnings/history`

## Models — `core/models/`

`User` / `UserSummary` / `AuthResult` / `OtpVerifyResult`, `Car` / `CarPhoto`,
`Booking` / `BookingPricing`, `Trip`, `Wallet` / `WalletTransaction`,
`ChatThread` / `ChatMessage`, `Review`, `Dispute`, `AppNotification`,
`PromoCode`, `HostVerification` / `HostVerificationStep`, `Earning` /
`EarningsSummary`.

All have hand-written `fromJson` that tolerate missing relations (`whenLoaded`),
string-encoded decimals, and both pagination shapes.

## Routes — `app/router.dart`

Public (unauthenticated): `/splash`, `/onboarding`, `/login`, `/register`, `/verify`.

Bottom-nav shell tabs: `/home`, `/trips`, `/messages`, `/wallet`, `/profile`.

Full-screen: `/search`, `/map`, `/car/:id`, `/datetime`, `/booking`,
`/booking/success`, `/bookings/:id`, `/trip/:id`, `/rate/:bookingId`,
`/reviews/:carId`, `/chat/:threadId`, `/kyc`, `/notifications`, `/settings`,
`/payment-methods`, `/host`, `/host/verify`, `/host/cars`, `/host/add-car`,
`/host/bookings`, `/host/earnings`.

A redirect guard keeps signed-out users on public routes and signed-in users out
of the auth screens; `/datetime`, `/booking`, `/booking/success` and `/chat`
receive their arguments via GoRouter `extra`.

## Realtime — `core/network/realtime_client.dart`

Connects to Laravel Reverb (`{WS_SCHEME}://{WS_HOST}:{WS_PORT}/app/{REVERB_APP_KEY}`),
authorises private channels through `{origin}/broadcasting/auth` with the bearer
token, and exposes a broadcast `Stream<RealtimeEvent>`. Used by the chat and live
trip screens; both also poll/refresh over REST so realtime is purely additive.
