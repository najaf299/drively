import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/booking.dart';
import '../core/models/car.dart';
import '../features/auth/domain/providers/auth_provider.dart';
import '../features/auth/presentation/screens/kyc_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/booking/domain/booking_draft.dart';
import '../features/booking/presentation/screens/booking_success_screen.dart';
import '../features/booking/presentation/screens/booking_summary_screen.dart';
import '../features/booking/presentation/screens/datetime_screen.dart';
import '../features/chat/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/discovery/presentation/screens/car_detail_screen.dart';
import '../features/discovery/presentation/screens/home_screen.dart';
import '../features/discovery/presentation/screens/map_screen.dart';
import '../features/discovery/presentation/screens/search_screen.dart';
import '../features/host/presentation/screens/add_car_screen.dart';
import '../features/host/presentation/screens/host_bookings_screen.dart';
import '../features/host/presentation/screens/host_cars_screen.dart';
import '../features/host/presentation/screens/host_dashboard_screen.dart';
import '../features/host/presentation/screens/host_earnings_screen.dart';
import '../features/host/presentation/screens/host_verification_screen.dart';
import '../features/profile/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/trip/presentation/screens/active_trip_screen.dart';
import '../features/trip/presentation/screens/booking_detail_screen.dart';
import '../features/trip/presentation/screens/rate_trip_screen.dart';
import '../features/trip/presentation/screens/reviews_screen.dart';
import '../features/trip/presentation/screens/trips_screen.dart';
import '../features/wallet/presentation/screens/payment_methods_screen.dart';
import '../features/wallet/presentation/screens/wallet_screen.dart';
import 'theme.dart';

/// Whether the user has completed the onboarding carousel. Overridden in
/// `main()` from SharedPreferences so the router can decide synchronously.
final onboardingSeenProvider = Provider<bool>((ref) => false);

/// Routes reachable while signed out.
const _publicRoutes = {
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/verify'
};

/// Bridges Riverpod auth-state changes into a [Listenable] for GoRouter.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isPublic = _publicRoutes.contains(loc);

      // Still restoring the session → wait on the splash.
      if (auth.status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }

      // Signed out → only public routes are allowed.
      if (!auth.isAuthenticated) {
        if (isPublic && loc != '/splash') return null;
        final seen = ref.read(onboardingSeenProvider);
        return seen ? '/login' : '/onboarding';
      }

      // Signed in → bounce away from auth/splash screens.
      if (auth.isAuthenticated && isPublic) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/verify',
        builder: (_, state) =>
            OtpScreen(initialPhone: state.uri.queryParameters['phone']),
      ),

      // Bottom-navigation shell.
      ShellRoute(
        builder: (_, __, child) => _ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/trips', builder: (_, __) => const TripsScreen()),
          GoRoute(
              path: '/messages', builder: (_, __) => const ChatListScreen()),
          GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Discovery / booking flow (full-screen).
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
      GoRoute(
        path: '/car/:id',
        builder: (_, state) =>
            CarDetailScreen(carId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/datetime',
        builder: (_, state) {
          final car = state.extra;
          if (car is! Car) return const _MissingArgs();
          return DateTimeScreen(car: car);
        },
      ),
      GoRoute(
        path: '/booking',
        builder: (_, state) {
          final draft = state.extra;
          if (draft is! BookingDraft) return const _MissingArgs();
          return BookingSummaryScreen(draft: draft);
        },
      ),
      GoRoute(
        path: '/booking/success',
        builder: (_, state) {
          final booking = state.extra;
          if (booking is! Booking) return const _MissingArgs();
          return BookingSuccessScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (_, state) =>
            BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/trip/:id',
        builder: (_, state) =>
            ActiveTripScreen(tripId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/rate/:bookingId',
        builder: (_, state) =>
            RateTripScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/reviews/:carId',
        builder: (_, state) =>
            ReviewsScreen(carId: state.pathParameters['carId']!),
      ),
      GoRoute(
        path: '/chat/:threadId',
        builder: (_, state) {
          final extra = (state.extra as Map?) ?? const {};
          return ChatScreen(
            threadId: state.pathParameters['threadId']!,
            recipientId: extra['recipientId'] as String?,
            recipientName: extra['name'] as String?,
            bookingId: extra['bookingId'] as String?,
          );
        },
      ),

      // Profile / account.
      GoRoute(path: '/kyc', builder: (_, __) => const KycScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/payment-methods',
          builder: (_, __) => const PaymentMethodsScreen()),

      // Host.
      GoRoute(path: '/host', builder: (_, __) => const HostDashboardScreen()),
      GoRoute(
          path: '/host/verify',
          builder: (_, __) => const HostVerificationScreen()),
      GoRoute(path: '/host/cars', builder: (_, __) => const HostCarsScreen()),
      GoRoute(path: '/host/add-car', builder: (_, __) => const AddCarScreen()),
      GoRoute(
          path: '/host/bookings',
          builder: (_, __) => const HostBookingsScreen()),
      GoRoute(
          path: '/host/earnings',
          builder: (_, __) => const HostEarningsScreen()),
    ],
  );
});

/// Bottom navigation host for the five primary tabs.
class _ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithNavBar({required this.child});

  static const _tabs = ['/home', '/trips', '/messages', '/wallet', '/profile'];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => location.startsWith(t));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexFor(location),
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover'),
          BottomNavigationBarItem(
              icon: Icon(Icons.luggage_outlined),
              activeIcon: Icon(Icons.luggage),
              label: 'Trips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

/// Fallback shown when a screen is opened without its required `extra` argument
/// (e.g. via a cold deep link).
class _MissingArgs extends StatelessWidget {
  const _MissingArgs();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 48, color: BrandColors.mutedFg),
              const SizedBox(height: Spacing.x4),
              const Text('This page needs to be opened from the app flow.',
                  textAlign: TextAlign.center),
              const SizedBox(height: Spacing.x4),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
