import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final SecureStorage _storage;

  AuthNotifier(this._authService, this._storage) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      try {
        final user = await _authService.getProfile();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } catch (e) {
        await logout();
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response =
          await _authService.login(email: email, password: password);
      await _storage.write(key: 'auth_token', value: response.accessToken);
      await _storage.write(key: 'refresh_token', value: response.refreshToken);
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
    } catch (e) {
      state =
          AuthState(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> register(
      String name, String email, String password, String phone) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      await _storage.write(key: 'auth_token', value: response.accessToken);
      await _storage.write(key: 'refresh_token', value: response.refreshToken);
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
    } catch (e) {
      state =
          AuthState(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response = await _authService.loginWithGoogle(idToken);
      await _storage.write(key: 'auth_token', value: response.accessToken);
      await _storage.write(key: 'refresh_token', value: response.refreshToken);
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
    } catch (e) {
      state =
          AuthState(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> loginWithApple(String identityToken) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response = await _authService.loginWithApple(identityToken);
      await _storage.write(key: 'auth_token', value: response.accessToken);
      await _storage.write(key: 'refresh_token', value: response.refreshToken);
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
    } catch (e) {
      state =
          AuthState(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> sendOtp(String phone) async {
    try {
      await _authService.sendOtp(phone);
    } catch (e) {
      state = AuthState(status: state.status, error: e.toString());
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    try {
      await _authService.verifyOtp(phone, code);
    } catch (e) {
      state = AuthState(status: state.status, error: e.toString());
    }
  }

  Future<void> updateProfile(
      {String? name, String? phone, String? avatarUrl}) async {
    if (state.user == null) return;
    try {
      final updatedUser = await _authService.updateProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      state = AuthState(status: state.status, error: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(secureStorageProvider),
  );
});
