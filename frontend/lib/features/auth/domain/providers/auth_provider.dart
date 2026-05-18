import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;
  final String? error;

  const AuthState({this.status = AuthStatus.initial, this.token, this.error});

  AuthState copyWith({AuthStatus? status, String? token, String? error}) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    // Implement login logic
  }

  Future<void> register(String name, String email, String password) async {
    // Implement register logic
  }

  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
