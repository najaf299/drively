/// Centralised, compile-time configuration.
///
/// Values are provided via `--dart-define` so the same binary can target
/// different environments without code changes.
class AppConfig {
  AppConfig._();

  /// Base URL of the REST API, including the `/api/v1` prefix.
  ///
  /// This default is only a fallback for a plain `flutter run`. To avoid editing
  /// this file every time your Wi-Fi (and Mac IP) changes, use the helper
  /// scripts instead — they auto-detect the right value at run time:
  ///   • Simulator:     ./run_sim.sh    (always uses localhost)
  ///   • Real iPhone:   ./run_phone.sh  (auto-detects the Mac's current LAN IP)
  /// You can still override manually with `--dart-define=API_URL=...`.
  /// (An Android emulator would use 10.0.2.2.)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.10:8000/api/v1',
  );

  /// Reverb host (without scheme/port).
  static const String wsHost = String.fromEnvironment(
    'WS_HOST',
    defaultValue: '192.168.1.10',
  );

  /// Reverb port.
  static const int wsPort = int.fromEnvironment('WS_PORT', defaultValue: 8080);

  /// WebSocket scheme: `ws` (local) or `wss` (TLS).
  static const String wsScheme = String.fromEnvironment(
    'WS_SCHEME',
    defaultValue: 'ws',
  );

  /// Public Reverb app key (matches `REVERB_APP_KEY` on the backend).
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'drivly-key',
  );

  /// Stripe publishable key for the Payment Sheet. Empty disables card flows.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Whether realtime features should attempt to connect.
  static bool get realtimeEnabled => wsHost.isNotEmpty;

  /// Whether Stripe card payments are configured.
  static bool get stripeEnabled => stripePublishableKey.isNotEmpty;
}
