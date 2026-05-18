import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, {String symbol = '\\$'}) {
    return '\$symbol\${amount.toStringAsFixed(2)}';
  }

  static String date(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '\${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '\${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '\${diff.inDays}d ago';
    if (diff.inHours > 0) return '\${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '\${diff.inMinutes}m ago';
    return 'just now';
  }

  static String distance(double km) {
    if (km < 1) return '\${(km * 1000).round()}m';
    return '\${km.toStringAsFixed(1)}km';
  }
}
