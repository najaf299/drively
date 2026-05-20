/// Defensive JSON parsing helpers.
///
/// The Laravel backend serialises money/coordinates using PostgreSQL `decimal`
/// columns which Eloquent casts to **strings** (e.g. `"45.00"`), while integers
/// and booleans may arrive as `int`/`bool` or numeric strings depending on the
/// driver. These helpers normalise those representations so every model can rely
/// on strongly-typed values without scattering ad-hoc casts everywhere.
library;

/// Parses [value] into a [double], accepting `num`, numeric `String` or `null`.
double asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Parses [value] into a nullable [double].
double? asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Parses [value] into an [int], accepting `num`, numeric `String` or `null`.
int asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Parses [value] into a nullable [int].
int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Parses [value] into a [bool]. Accepts `bool`, `int` (1/0) and `String`.
bool asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }
  return fallback;
}

/// Coerces [value] into a [String], or [fallback] when null.
String asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

/// Coerces [value] into a nullable [String].
String? asStringOrNull(dynamic value) => value?.toString();

/// Parses an ISO-8601 [value] into a [DateTime], or null when unparseable.
DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

/// Parses a JSON list of strings (used for `features`, `tags`, `photo_urls`).
List<String> asStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}

/// Safely casts [value] to a `Map<String, dynamic>`, or null.
Map<String, dynamic>? asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Maps a JSON list into typed objects using [mapper], tolerating `null`.
List<T> asList<T>(dynamic value, T Function(Map<String, dynamic>) mapper) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => mapper(Map<String, dynamic>.from(e)))
        .toList();
  }
  return <T>[];
}
