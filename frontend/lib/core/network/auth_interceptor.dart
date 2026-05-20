import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

/// Storage key for the Sanctum bearer token.
const kAuthTokenKey = 'auth_token';

/// Injects the bearer token on every request and broadcasts auth failures.
///
/// On a `401` the [onUnauthorized] callback fires so the app can clear session
/// state and route the user back to sign-in. (Sanctum issues a single
/// non-refreshable token, so there is no silent-refresh step.)
class AuthInterceptor extends Interceptor {
  final Ref ref;

  /// Invoked when the API rejects the current token.
  final void Function()? onUnauthorized;

  AuthInterceptor(this.ref, {this.onUnauthorized});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: kAuthTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
