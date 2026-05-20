import 'package:dio/dio.dart';
import '../errors/app_exception.dart';

/// Converts any thrown error into a user-presentable [AppException].
///
/// Use at service boundaries: `catch (e) { throw mapError(e); }`.
AppException mapError(Object error) {
  if (error is AppException) return error;
  if (error is DioException) return AppException.fromDio(error);
  return AppException(error.toString());
}
