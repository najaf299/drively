import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_config.dart';
import 'dio_client.dart';

/// A realtime event received over the WebSocket: `{ channel, event, data }`.
class RealtimeEvent {
  final String channel;
  final String event;
  final Map<String, dynamic> data;
  const RealtimeEvent(this.channel, this.event, this.data);
}

/// Minimal Laravel Reverb (Pusher-protocol) WebSocket client.
///
/// Realtime is **additive**: chat and trips work fully over REST, and this
/// client simply pushes live updates on top. All failures are swallowed so a
/// missing/blocked WebSocket never breaks the app.
class RealtimeClient {
  final Dio _dio;
  RealtimeClient(this._dio);

  WebSocketChannel? _ws;
  String? _socketId;
  bool _connecting = false;
  final Set<String> _channels = {};
  final _controller = StreamController<RealtimeEvent>.broadcast();

  /// Broadcast stream of all incoming app events.
  Stream<RealtimeEvent> get events => _controller.stream;

  /// Origin (scheme + host[:port]) of the Laravel app, derived from the API URL,
  /// used for the `/broadcasting/auth` private-channel handshake.
  String get _appOrigin {
    var base = AppConfig.apiBaseUrl;
    final marker = base.indexOf('/api');
    if (marker != -1) base = base.substring(0, marker);
    return base;
  }

  Future<void> _connect() async {
    if (_ws != null || _connecting || !AppConfig.realtimeEnabled) return;
    _connecting = true;
    try {
      final uri = Uri.parse(
        '${AppConfig.wsScheme}://${AppConfig.wsHost}:${AppConfig.wsPort}'
        '/app/${AppConfig.reverbAppKey}'
        '?protocol=7&client=dart&version=2.0&flash=false',
      );
      final ws = WebSocketChannel.connect(uri);
      _ws = ws;
      ws.stream.listen(
        _onMessage,
        onError: (_) => _reset(),
        onDone: _reset,
        cancelOnError: true,
      );
    } catch (e) {
      _debug('connect failed: $e');
      _reset();
    } finally {
      _connecting = false;
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = decoded['event'] as String? ?? '';
      var data = decoded['data'];
      if (data is String && data.isNotEmpty) {
        data = jsonDecode(data);
      }
      final map =
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

      if (event == 'pusher:connection_established') {
        _socketId = map['socket_id']?.toString();
        // Re-subscribe to any channels requested before the socket was ready.
        for (final channel in _channels.toList()) {
          _authoriseAndSubscribe(channel);
        }
        return;
      }
      if (event.startsWith('pusher')) return; // internal protocol frames

      _controller.add(
        RealtimeEvent(decoded['channel']?.toString() ?? '', event, map),
      );
    } catch (e) {
      _debug('message parse failed: $e');
    }
  }

  /// Subscribes to a private channel (the backend channels are all private),
  /// connecting lazily if needed.
  Future<void> subscribePrivate(String channel) async {
    if (!AppConfig.realtimeEnabled) return;
    final name = channel.startsWith('private-') ? channel : 'private-$channel';
    _channels.add(name);
    await _connect();
    if (_socketId != null) {
      await _authoriseAndSubscribe(name);
    }
  }

  void unsubscribe(String channel) {
    final name = channel.startsWith('private-') ? channel : 'private-$channel';
    _channels.remove(name);
    _send({
      'event': 'pusher:unsubscribe',
      'data': {'channel': name},
    });
  }

  Future<void> _authoriseAndSubscribe(String channel) async {
    try {
      final res = await _dio.post(
        '$_appOrigin/broadcasting/auth',
        data: {'socket_id': _socketId, 'channel_name': channel},
        options: Options(contentType: Headers.jsonContentType),
      );
      final auth = (res.data is Map) ? res.data['auth']?.toString() : null;
      if (auth == null) return;
      _send({
        'event': 'pusher:subscribe',
        'data': {'auth': auth, 'channel': channel},
      });
    } catch (e) {
      _debug('channel auth failed for $channel: $e');
    }
  }

  void _send(Map<String, dynamic> message) {
    try {
      _ws?.sink.add(jsonEncode(message));
    } catch (_) {/* ignore */}
  }

  void _reset() {
    _ws = null;
    _socketId = null;
  }

  void dispose() {
    _ws?.sink.close();
    _controller.close();
  }

  void _debug(String message) {
    if (kDebugMode) debugPrint('[Realtime] $message');
  }
}

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(ref.read(dioProvider));
  ref.onDispose(client.dispose);
  return client;
});
