import '../utils/json_utils.dart';

/// Helpers for unwrapping the backend's standard response envelope:
///
/// ```json
/// { "success": true, "message": "...", "data": <payload> }
/// ```
///
/// Pagination is inconsistent across endpoints: resource collections nested in
/// the envelope serialise as a bare JSON array, while raw paginators serialise
/// as a `{ "data": [...], "current_page": 1, "total": 42, ... }` object. These
/// helpers normalise both shapes.
class ApiResponse {
  ApiResponse._();

  /// Extracts the `data` field from the response envelope.
  static dynamic data(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  /// Returns the human-readable `message` from the envelope, if any.
  static String? message(dynamic body) {
    if (body is Map) return body['message']?.toString();
    return null;
  }
}

/// A typed, paginated list of [T] with optional pagination metadata.
class Paginated<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const Paginated({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
  });

  bool get hasMore => currentPage < lastPage;

  /// Builds a [Paginated] from any envelope payload, tolerating both the
  /// bare-array and paginator-object shapes described above.
  factory Paginated.from(
    dynamic payload,
    T Function(Map<String, dynamic>) mapper,
  ) {
    // Paginator object: { data: [...], current_page, last_page, ... }
    if (payload is Map && payload['data'] is List) {
      return Paginated<T>(
        items: asList<T>(payload['data'], mapper),
        currentPage: asInt(payload['current_page'], fallback: 1),
        lastPage: asInt(payload['last_page'], fallback: 1),
        perPage: asInt(payload['per_page'], fallback: 20),
        total: asInt(payload['total']),
      );
    }
    // Bare array (resource collection nested in the envelope).
    if (payload is List) {
      final items = asList<T>(payload, mapper);
      return Paginated<T>(
        items: items,
        total: items.length,
        perPage: items.length,
      );
    }
    return Paginated<T>(items: const []);
  }
}
