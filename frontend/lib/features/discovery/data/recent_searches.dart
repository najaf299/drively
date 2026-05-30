import '../../../core/storage/local_cache.dart';

/// Local store for the user's last search terms (newest first).
class RecentSearches {
  RecentSearches._();

  static const _key = 'recent_searches';
  static const _max = 8;

  static List<String> all() => LocalCache.getStringList(_key);

  static Future<void> add(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    final existing = LocalCache.getStringList(_key);
    final next = [t, ...existing.where((e) => e.toLowerCase() != t.toLowerCase())];
    if (next.length > _max) next.removeRange(_max, next.length);
    await LocalCache.setStringList(_key, next);
  }

  static Future<void> remove(String term) async {
    final next = LocalCache.getStringList(_key)
        .where((e) => e.toLowerCase() != term.toLowerCase())
        .toList();
    await LocalCache.setStringList(_key, next);
  }

  static Future<void> clear() async {
    await LocalCache.setStringList(_key, const []);
  }
}
