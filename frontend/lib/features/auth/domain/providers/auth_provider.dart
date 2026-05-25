import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/user.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, authenticating }

/// Immutable auth state consumed by the router and screens.
@immutable
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isBusy => status == AuthStatus.authenticating;

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Owns the session: bootstrap-from-storage, sign in/up, OTP, profile, logout.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._service, this._storage) : super(const AuthState()) {
    bootstrap();
  }

  /// On launch, restore the session if a token is present and still valid.
  Future<void> bootstrap() async {
    final token = await _storage.read(key: kAuthTokenKey);
    if (token == null || token.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _service.getProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _clearSession();
    }
  }

  Future<bool> login(String email, String password) =>
      _run(() => _service.login(email: email, password: password));

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'customer',
  }) =>
      _run(() => _service.register(
            name: name,
            email: email,
            password: password,
            phone: phone,
            role: role,
          ));

  Future<bool> loginWithGoogle(String idToken,
          {String? name, String? email, String? avatarUrl}) =>
      _run(() => _service.loginWithGoogle(idToken,
          name: name, email: email, avatarUrl: avatarUrl));

  Future<bool> loginWithApple(
    String token, {
    required String authorizationCode,
    String? name,
    String? email,
  }) =>
      _run(() => _service.loginWithApple(
            token,
            authorizationCode: authorizationCode,
            name: name,
            email: email,
          ));

  /// Requests a password-reset code. Returns the dev code in debug builds
  /// (so it can be prefilled), otherwise null. Throws on failure.
  Future<String?> forgotPassword(String email) =>
      _service.forgotPassword(email);

  /// Verifies the reset code, sets the new password and signs the user in.
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
  }) =>
      _run(() => _service.resetPassword(
            email: email,
            code: code,
            password: password,
          ));

  /// Sends an OTP code; throws [AppException] on failure for the UI to surface.
  Future<void> sendOtp(String phone) => _service.sendOtp(phone);

  /// Verifies an OTP. If it resolves to an existing account, the session is
  /// established and `true` is returned; new numbers return `false`.
  Future<bool> verifyOtp(String phone, String code) async {
    final result = await _service.verifyOtp(phone, code);
    if (!result.isNew && result.user != null && result.token != null) {
      await _storage.write(key: kAuthTokenKey, value: result.token);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      return true;
    }
    return false;
  }

  Future<void> updateProfile(Map<String, dynamic> changes) async {
    final updated = await _service.updateProfile(changes);
    state = state.copyWith(user: updated);
  }

  /// Uploads a new profile photo and updates the in-memory user.
  Future<void> uploadAvatar(File file) async {
    final updated = await _service.uploadAvatar(file);
    state = state.copyWith(user: updated);
  }

  /// Re-fetches the current user (e.g. after KYC / host verification changes).
  Future<void> refreshUser() async {
    try {
      final user = await _service.getProfile();
      state = state.copyWith(user: user);
    } catch (_) {/* keep current state */}
  }

  Future<void> logout() async {
    await _service.logout();
    await _clearSession();
  }

  /// Invoked when the API rejects the token (HTTP 401).
  Future<void> handleUnauthorized() async {
    if (state.status == AuthStatus.unauthenticated) return;
    await _clearSession();
  }

  // ── internals ───────────────────────────────────────────────────────────
  Future<bool> _run(Future<AuthResult> Function() action) async {
    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    try {
      final result = await action();
      await _storage.write(key: kAuthTokenKey, value: result.token);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      return true;
    } on AppException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
      return false;
    } catch (e) {
      state =
          AuthState(status: AuthStatus.unauthenticated, error: e.toString());
      return false;
    }
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: kAuthTokenKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(secureStorageProvider),
  );
  // React to global 401s emitted by the Dio interceptor.
  ref.listen<int>(unauthorizedSignalProvider, (_, __) {
    notifier.handleUnauthorized();
  });
  return notifier;
});

/// Convenience: the current user's id (or null when signed out).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.id;
});
