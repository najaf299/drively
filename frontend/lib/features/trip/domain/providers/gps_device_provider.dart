import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single command issued to the GPS lock unit, for the activity log.
@immutable
class GpsCommand {
  final String label;
  final DateTime at;
  final bool ok;
  final IconData icon;
  const GpsCommand({
    required this.label,
    required this.at,
    required this.ok,
    required this.icon,
  });
}

/// Simulated telemetry + state for a vehicle's GPS lock/immobilizer unit.
///
/// This is the prototype of the client's core idea: cars are parked & locked
/// with a GPS unit, and the app sends lock/unlock (and engine-immobilizer)
/// commands over an API. The data here is simulated on-device so the flow is
/// fully demoable without the third-party GPS provider's API.
@immutable
class GpsDeviceState {
  final bool locked;
  final bool immobilized; // engine cut-off (anti-theft)
  final int batteryPct; // GPS unit battery
  final int signalBars; // 0–4 cellular signal
  final double lat;
  final double lng;
  final DateTime lastSync;
  final bool sending; // a command is in flight
  final String? sendingLabel; // what we're currently doing
  final List<GpsCommand> history;
  final bool seeded;

  const GpsDeviceState({
    required this.locked,
    required this.immobilized,
    required this.batteryPct,
    required this.signalBars,
    required this.lat,
    required this.lng,
    required this.lastSync,
    this.sending = false,
    this.sendingLabel,
    this.history = const [],
    this.seeded = false,
  });

  bool get online => signalBars > 0;

  GpsDeviceState copyWith({
    bool? locked,
    bool? immobilized,
    int? batteryPct,
    int? signalBars,
    double? lat,
    double? lng,
    DateTime? lastSync,
    bool? sending,
    String? sendingLabel,
    List<GpsCommand>? history,
    bool? seeded,
  }) {
    return GpsDeviceState(
      locked: locked ?? this.locked,
      immobilized: immobilized ?? this.immobilized,
      batteryPct: batteryPct ?? this.batteryPct,
      signalBars: signalBars ?? this.signalBars,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      lastSync: lastSync ?? this.lastSync,
      sending: sending ?? this.sending,
      sendingLabel: sending == false ? null : (sendingLabel ?? this.sendingLabel),
      history: history ?? this.history,
      seeded: seeded ?? this.seeded,
    );
  }
}

/// Owns the simulated device and applies commands with a realistic round-trip
/// delay (mimicking talking to the GPS provider's network).
class GpsDeviceNotifier extends StateNotifier<GpsDeviceState> {
  GpsDeviceNotifier()
      : super(GpsDeviceState(
          locked: true, // cars sit parked & locked until paid for
          immobilized: true,
          batteryPct: 86,
          signalBars: 4,
          lat: 25.2048, // sensible default until seeded from the trip
          lng: 55.2708,
          lastSync: DateTime.now(),
        ));

  final _rng = Random();

  /// Seed real coordinates from the trip once, if available.
  void seed({double? lat, double? lng}) {
    if (state.seeded) return;
    state = state.copyWith(
      lat: lat ?? state.lat,
      lng: lng ?? state.lng,
      seeded: true,
      lastSync: DateTime.now(),
    );
  }

  Future<void> unlock() => _send(
        label: 'Unlock doors',
        icon: Icons.lock_open_rounded,
        apply: (s) => s.copyWith(locked: false, immobilized: false),
      );

  Future<void> lock() => _send(
        label: 'Lock doors',
        icon: Icons.lock_rounded,
        apply: (s) => s.copyWith(locked: true),
      );

  Future<void> toggleImmobilizer() => _send(
        label: state.immobilized ? 'Release engine' : 'Immobilize engine',
        icon: state.immobilized
            ? Icons.power_settings_new_rounded
            : Icons.block_rounded,
        apply: (s) => s.copyWith(immobilized: !s.immobilized),
      );

  /// Re-poll the unit: nudges telemetry + coordinates slightly to feel live.
  Future<void> ping() => _send(
        label: 'Ping device',
        icon: Icons.sensors_rounded,
        delay: const Duration(milliseconds: 900),
        apply: (s) => s.copyWith(
          batteryPct: (s.batteryPct - _rng.nextInt(2)).clamp(1, 100),
          signalBars: 3 + _rng.nextInt(2), // 3–4 bars
          lat: s.lat + (_rng.nextDouble() - 0.5) * 0.0008,
          lng: s.lng + (_rng.nextDouble() - 0.5) * 0.0008,
        ),
      );

  Future<void> _send({
    required String label,
    required IconData icon,
    required GpsDeviceState Function(GpsDeviceState) apply,
    Duration delay = const Duration(milliseconds: 1700),
  }) async {
    if (state.sending) return;
    state = state.copyWith(sending: true, sendingLabel: '$label…');
    await Future<void>.delayed(delay);
    final updated = apply(state).copyWith(
      sending: false,
      lastSync: DateTime.now(),
    );
    final entry = GpsCommand(label: label, at: DateTime.now(), ok: true, icon: icon);
    state = updated.copyWith(
      history: [entry, ...updated.history].take(8).toList(),
    );
  }
}

/// One simulated device per trip, kept alive for the session so command history
/// and lock state survive navigating in and out of the control screen.
final gpsDeviceProvider =
    StateNotifierProvider.family<GpsDeviceNotifier, GpsDeviceState, String>(
  (ref, tripId) => GpsDeviceNotifier(),
);
