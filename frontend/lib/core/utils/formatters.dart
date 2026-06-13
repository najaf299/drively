import 'package:intl/intl.dart';

/// Display formatting helpers for money, dates and durations.
class Formatters {
  Formatters._();

  static final NumberFormat _money = NumberFormat('#,##0.00');
  static final NumberFormat _moneyCompact = NumberFormat('#,##0');

  /// Active display currency symbol/prefix, driven by the user's Settings
  /// (`preferred_currency`). Updated via [configure] from the settings listener
  /// in `app.dart`, so every `money`/`moneyCompact` call reflects the user's
  /// choice without per-call-site changes. Note: amounts are formatted with the
  /// selected symbol; cross-currency FX conversion is a later (dependent) step.
  static String currencySymbol = r'$';

  /// Whether distances render in miles instead of kilometres, driven by the
  /// user's Settings (`preferred_units`). The conversion is exact.
  static bool useMiles = false;

  static const Map<String, String> _currencySymbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'AED ',
    'SAR': 'SAR ',
  };

  /// Applies the user's currency/units preferences globally. Unknown currency
  /// codes fall back to a `"CODE "` prefix so any ISO code stays readable.
  static void configure({String? currencyCode, String? units}) {
    if (currencyCode != null && currencyCode.isNotEmpty) {
      final code = currencyCode.toUpperCase();
      currencySymbol = _currencySymbols[code] ?? '$code ';
    }
    if (units != null && units.isNotEmpty) useMiles = units == 'mi';
  }

  /// `$1,234.56` in the active currency (override [symbol] for a fixed one).
  static String money(num amount, {String? symbol}) =>
      '${symbol ?? currencySymbol}${_money.format(amount)}';

  /// `$1,235` (no decimals) — for summary/hero figures.
  static String moneyCompact(num amount, {String? symbol}) =>
      '${symbol ?? currencySymbol}${_moneyCompact.format(amount)}';

  /// `Jun 14, 2026`
  static String date(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  /// `Jun 14`
  static String dayMonth(DateTime date) => DateFormat('MMM d').format(date);

  /// `Jun 14, 2026 · 09:30`
  static String dateTime(DateTime date) =>
      DateFormat('MMM d, yyyy · HH:mm').format(date);

  /// `09:30`
  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  /// Relative time, e.g. `3h ago`, `just now`.
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  /// `850m` / `4.2km` — or `460ft` / `0.3mi` when the user prefers miles.
  static String distance(double km) {
    if (useMiles) {
      final mi = km * 0.621371;
      if (mi < 0.1) return '${(mi * 5280).round()}ft';
      return '${mi.toStringAsFixed(1)}mi';
    }
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }

  /// `1d 4h 22m` countdown formatting; returns `Overdue` for negatives.
  static String countdown(Duration d) {
    if (d.isNegative) return 'Overdue';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Pluralises [word] based on [count]: `1 day`, `3 days`.
  static String plural(int count, String word) =>
      '$count $word${count == 1 ? '' : 's'}';
}
