import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});

/// Thin wrapper around the `/auth/*` and `/profile` endpoints.
///
/// The backend issues a single (non-refreshable) Laravel Sanctum token, so the
/// auth payload is `{ user, token }` — there is no refresh token.
class AuthService {
  final Dio _dio;
  AuthService(this._dio);

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'customer',
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': role,
      });
      return AuthResult.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      return AuthResult.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<AuthResult> loginWithGoogle(
    String idToken, {
    String? name,
    String? email,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.googleAuth, data: {
        'id_token': idToken,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      });
      return AuthResult.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<AuthResult> loginWithApple(
    String identityToken, {
    required String authorizationCode,
    String? name,
    String? email,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.appleAuth, data: {
        'identity_token': identityToken,
        // The backend requires an authorization_code alongside the token.
        'authorization_code': authorizationCode,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      });
      return AuthResult.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Requests a password-reset code for [email]. Returns the dev code when the
  /// backend is in debug mode (so the flow is testable without an email
  /// provider); otherwise null.
  Future<String?> forgotPassword(String email) async {
    try {
      final res = await _dio.post(ApiEndpoints.forgotPassword, data: {
        'email': email,
      });
      final data = ApiResponse.data(res.data);
      if (data is Map && data['dev_code'] != null) {
        return data['dev_code'].toString();
      }
      return null;
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Verifies the reset [code] and sets a new [password]. On success the backend
  /// returns a fresh session so the user lands signed in.
  Future<AuthResult> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.resetPassword, data: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password,
      });
      return AuthResult.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post(ApiEndpoints.sendOtp, data: {'phone': phone});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<OtpVerifyResult> verifyOtp(String phone, String code) async {
    try {
      final res = await _dio.post(ApiEndpoints.verifyOtp, data: {
        'phone': phone,
        'code': code,
      });
      return OtpVerifyResult.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Even if the server call fails, the client clears its own session.
    }
  }

  Future<User> getProfile() async {
    try {
      final res = await _dio.get(ApiEndpoints.profile);
      return User.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<User> updateProfile(Map<String, dynamic> changes) async {
    try {
      final res = await _dio.put(ApiEndpoints.profile, data: changes);
      return User.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }
}
