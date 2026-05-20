import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_config.dart';
import 'auth_interceptor.dart';

/// Bumped whenever the API returns `401`, so session-aware providers (auth,
/// router) can react and route the user back to sign-in. Kept in the `core`
/// layer to avoid a `core → features` import cycle.
final unauthorizedSignalProvider = StateProvider<int>((ref) => 0);

/// The shared, authenticated [Dio] instance.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      ref,
      onUnauthorized: () {
        // Trigger a global sign-out without importing the auth feature here.
        ref.read(unauthorizedSignalProvider.notifier).state++;
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  return dio;
});
