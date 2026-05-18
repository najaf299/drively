import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
      GoRoute(path: '/onboarding', builder: (context, state) => const Scaffold(body: Center(child: Text('Onboarding')))),
      GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Center(child: Text('Login')))),
      GoRoute(path: '/register', builder: (context, state) => const Scaffold(body: Center(child: Text('Register')))),
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
              BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookings'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
        routes: [
          GoRoute(path: '/discover', builder: (context, state) => const Center(child: Text('Discover'))),
          GoRoute(path: '/bookings', builder: (context, state) => const Center(child: Text('Bookings'))),
          GoRoute(path: '/chat', builder: (context, state) => const Center(child: Text('Chat'))),
          GoRoute(path: '/profile', builder: (context, state) => const Center(child: Text('Profile'))),
        ],
      ),
      GoRoute(path: '/car/:id', builder: (context, state) => const Scaffold(body: Center(child: Text('Car Detail')))),
      GoRoute(path: '/booking/:id', builder: (context, state) => const Scaffold(body: Center(child: Text('Booking Detail')))),
    ],
  );
});
