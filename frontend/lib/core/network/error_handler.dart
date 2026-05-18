import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  AppException(this.message, {this.statusCode, this.data});

  factory AppException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException('Connection timeout', statusCode: 408);
      case DioExceptionType.badResponse:
        final message = error.response?.data?['message'] ?? 'Something went wrong';
        return AppException(message, statusCode: error.response?.statusCode, data: error.response?.data);
      case DioExceptionType.cancel:
        return AppException('Request cancelled');
      default:
        return AppException('No internet connection');
    }
  }

  @override
  String toString() => message;
}
