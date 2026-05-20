import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/user.dart';
import '../../../core/network/dio_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<LoginResponse> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );
      return LoginResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return LoginResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<LoginResponse> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.googleAuth,
        data: {'id_token': idToken},
      );
      return LoginResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<LoginResponse> loginWithApple(String identityToken) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.appleAuth,
        data: {'identity_token': identityToken},
      );
      return LoginResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post(
        ApiEndpoints.sendOtp,
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    try {
      await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': phone, 'code': code},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.profile,
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      );
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final message = error.response!.data['message'] ?? 'An error occurred';
      
      switch (statusCode) {
        case 401:
          return Exception('Unauthorized: $message');
        case 422:
          return Exception('Validation error: $message');
        case 429:
          return Exception('Too many requests. Please try again later.');
        default:
          return Exception(message);
      }
    }
    return Exception('Network error: ${error.message}');
  }
}
