import 'package:dio/dio.dart';

import '../constants/app_config.dart';

/// Application-level exception with a user-presentable [message].
///
/// This is the single error type surfaced to the UI. Network/Dio failures are
/// translated into an [AppException] (or one of its subtypes) via
/// [AppException.fromDio] so screens never deal with raw [DioException]s.
class AppException implements Exception {
  /// Human-readable message safe to show to the user.
  final String message;

  /// HTTP status code, when the error originated from a response.
  final int? statusCode;

  /// Field-level validation errors keyed by field name (HTTP 422).
  final Map<String, List<String>>? validationErrors;

  const AppException(
    this.message, {
    this.statusCode,
    this.validationErrors,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;
  bool get isNotFound => statusCode == 404;

  /// Translates a [DioException] into a friendly [AppException].
  factory AppException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(_devNetworkMessage(
          'Connection timed out. Please try again.',
        ));
      case DioExceptionType.connectionError:
        return NetworkException(_devNetworkMessage('No internet connection.'));
      case DioExceptionType.cancel:
        return const AppException('Request cancelled.');
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return NetworkException(error.message ?? 'Something went wrong.');
    }
  }

  static AppException _fromResponse(Response<dynamic>? response) {
    final code = response?.statusCode;
    final body = response?.data;

    String message = 'Something went wrong.';
    Map<String, List<String>>? validation;

    if (body is Map) {
      if (body['message'] is String && (body['message'] as String).isNotEmpty) {
        message = body['message'] as String;
      }
      // Laravel validation errors: { errors: { field: [..] } }
      final errors = body['errors'];
      if (errors is Map) {
        validation = errors.map(
          (key, value) => MapEntry(
            key.toString(),
            (value is List)
                ? value.map((e) => e.toString()).toList()
                : <String>[value.toString()],
          ),
        );
        // Prefer the first validation message when the top-level one is generic.
        final first = validation.values
            .firstWhere((l) => l.isNotEmpty, orElse: () => const [])
            .firstOrNull;
        if (first != null && message == 'Something went wrong.') {
          message = first;
        }
      }
    }

    if (code == 401) return AppException(message, statusCode: 401);
    if (code == 429) {
      return const AppException(
        'Too many attempts. Please try again later.',
        statusCode: 429,
      );
    }
    if (code != null && code >= 500) {
      return ServerException(message);
    }

    return AppException(message,
        statusCode: code, validationErrors: validation);
  }

  @override
  String toString() => message;
}

/// Extra hint for local HTTP builds (release phone runs use http:// LAN URLs).
String _devNetworkMessage(String base) {
  if (!AppConfig.apiBaseUrl.startsWith('http://')) return base;
  return '$base\n\n'
      'API: ${AppConfig.apiBaseUrl}\n'
      'On a real iPhone: start the backend with '
      '`composer serve:lan` (or `php artisan serve --host=0.0.0.0`), '
      'then reinstall with `frontend/run_phone.sh`.';
}

/// No connectivity / transport failure.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

/// Server-side (5xx) failure.
class ServerException extends AppException {
  const ServerException([super.message = 'Server error. Please try again.']);
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
