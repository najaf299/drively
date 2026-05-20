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

  Future<AuthResult> loginWithGoogle(String idToken) async {
    try {
      final res = await _dio.post(ApiEndpoints.googleAuth, data: {
        'id_token': idToken,
      });
      return AuthResult.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<AuthResult> loginWithApple(String identityToken) async {
    try {
      final res = await _dio.post(ApiEndpoints.appleAuth, data: {
        'identity_token': identityToken,
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
