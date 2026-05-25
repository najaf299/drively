import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../domain/providers/gps_device_provider.dart';

/// The connected-car control center — the prototype of the client's core idea:
/// each car carries a GPS lock unit; the app sends lock / unlock / immobilize
/// commands and reads live telemetry. Device state is simulated on-device so the
/// whole flow is demoable before the third-party GPS API is wired up.
class GpsControlScreen extends ConsumerStatefulWidget {
  final String tripId;
  final double? seedLat;
  final double? seedLng;
  final String? carName;
  final String? plate;

  const GpsControlScreen({
    super.key,
    required this.tripId,
    this.seedLat,
    this.seedLng,
    this.carName,
    this.plate,
  });

  @override
  ConsumerState<GpsControlScreen> createState() => _GpsControlScreenState();
}

class _GpsControlScreenState extends ConsumerState<GpsControlScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(gpsDeviceProvider(widget.tripId).notifier)
          .seed(lat: widget.seedLat, lng: widget.seedLng);
    });
  }

  GpsDeviceNotifier get _device =>
      ref.read(gpsDeviceProvider(widget.tripId).notifier);

  Future<void> _toggleLock(GpsDeviceState s) async {
    if (s.sending) return;
    if (s.locked) {
      await _device.unlock();
      _toast('Car unlocked — doors open, engine ready.', SnackType.success);
    } else {
      await _device.lock();
      _toast('Car locked — have a safe trip.', SnackType.success);
    }
  }

  void _toast(String msg, SnackType type) {
    if (!mounted) return;
    AppSnack.show(context, msg, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gpsDeviceProvider(widget.tripId));
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header row.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x2),
              child: Row(
                children: [
                  _circleBack(),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Car control', style: text.headlineMedium),
                        Text(
                          widget.carName ?? 'GPS lock unit',
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _ConnectionPill(online: s.online),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
                children: [
                  _LockHero(
                    state: s,
                    plate: widget.plate,
                    onTap: () => _toggleLock(s),
                  ),
                  const SizedBox(height: Spacing.x5),
                  _telemetryGrid(s, text),
                  const SizedBox(height: Spacing.x4),
                  _locationCard(s, text),
                  const SizedBox(height: Spacing.x4),
                  _immobilizerCard(s, text),
                  const SizedBox(height: Spacing.x5),
                  _historySection(s, text),
                  const SizedBox(height: Spacing.x5),
                  _safetyNote(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Telemetry grid ─────────────────────────────────────────────────────────
  Widget _telemetryGrid(GpsDeviceState s, TextTheme text) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.cell_tower_rounded,
            label: 'Signal',
            valueWidget: _SignalBars(bars: s.signalBars),
            ok: s.signalBars >= 2,
          ),
        ),
        const SizedBox(width: Spacing.x3),
        Expanded(
          child: _StatTile(
            icon: Icons.battery_charging_full_rounded,
            label: 'Unit battery',
            value: '${s.batteryPct}%',
            ok: s.batteryPct > 20,
          ),
        ),
        const SizedBox(width: Spacing.x3),
        Expanded(
          child: _StatTile(
            icon: s.immobilized ? Icons.block_rounded : Icons.bolt_rounded,
            label: 'Engine',
            value: s.immobilized ? 'Locked' : 'Ready',
            ok: !s.immobilized,
          ),
        ),
      ],
    );
  }

  // ── Location card ────────────────────────────────────────────────────────
  Widget _locationCard(GpsDeviceState s, TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined,
                  color: BrandColors.primary, size: Sizes.icon),
              const SizedBox(width: Spacing.x2),
              Text('Live location', style: text.titleMedium),
              const Spacer(),
              Text('synced ${_ago(s.lastSync)}', style: text.bodySmall),
            ],
          ),
          const SizedBox(height: Spacing.x3),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.x3, vertical: Spacing.x3),
            decoration: BoxDecoration(
              color: BrandColors.surface2,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Icon(Icons.my_location_rounded,
                    size: 18, color: BrandColors.mutedFg),
                const SizedBox(width: Spacing.x2),
                Expanded(
                  child: Text(
                    '${s.lat.toStringAsFixed(5)},  ${s.lng.toStringAsFixed(5)}',
                    style: BrandText.mono(size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.x3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: s.sending ? null : () => _device.ping(),
              icon: const Icon(Icons.sensors_rounded, size: Sizes.iconSm),
              label: const Text('Ping device'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Engine immobilizer ─────────────────────────────────────────────────────
  Widget _immobilizerCard(GpsDeviceState s, TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: Sizes.avatarMd,
            height: Sizes.avatarMd,
            decoration: BoxDecoration(
              color: (s.immobilized ? BrandColors.warning : BrandColors.success)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(
              s.immobilized
                  ? Icons.block_rounded
                  : Icons.power_settings_new_rounded,
              color: s.immobilized ? BrandColors.warning : BrandColors.success,
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Engine immobilizer', style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  s.immobilized
                      ? 'Engine is cut off (anti-theft).'
                      : 'Engine can be started.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: !s.immobilized,
            onChanged:
                s.sending ? null : (_) => _device.toggleImmobilizer(),
          ),
        ],
      ),
    );
  }

  // ── Command log ─────────────────────────────────────────────────────────
  Widget _historySection(GpsDeviceState s, TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COMMAND LOG',
            style: text.labelSmall?.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: Spacing.x3),
        Container(
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: BrandColors.border),
          ),
          child: s.history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Spacing.x5),
                  child: Center(
                    child: Text('No commands sent yet.',
                        style: text.bodySmall),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < s.history.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: Spacing.x4),
                      _historyRow(s.history[i], text),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _historyRow(GpsCommand c, TextTheme text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4, vertical: Spacing.x3),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: BrandColors.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(c.icon, size: 18, color: BrandColors.success),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(child: Text(c.label, style: text.bodyMedium)),
          Text(_ago(c.at), style: text.bodySmall),
          const SizedBox(width: Spacing.x2),
          Icon(Icons.check_circle,
              size: 16, color: BrandColors.success),
        ],
      ),
    );
  }

  Widget _safetyNote(TextTheme text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined,
            size: Sizes.iconSm, color: BrandColors.mutedFg),
        const SizedBox(width: Spacing.x2),
        Expanded(
          child: Text(
            'Commands are sent securely to the vehicle’s GPS unit. Only unlock '
            'when you’re next to the car, and lock it once it’s returned.',
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _circleBack() {
    return InkWell(
      onTap: () => context.canPop() ? context.pop() : context.go('/trips'),
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back,
            size: 20, color: BrandColors.foreground),
      ),
    );
  }
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 45) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

// ── The big animated lock/unlock control ───────────────────────────────────
class _LockHero extends StatefulWidget {
  final GpsDeviceState state;
  final String? plate;
  final VoidCallback onTap;
  const _LockHero({required this.state, required this.onTap, this.plate});

  @override
  State<_LockHero> createState() => _LockHeroState();
}

class _LockHeroState extends State<_LockHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final text = Theme.of(context).textTheme;
    final unlocked = !s.locked;
    final accent = unlocked ? BrandColors.primary : BrandColors.foreground;

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: Spacing.x6, horizontal: Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.xxl),
        border: Border.all(
          color: unlocked
              ? BrandColors.primary.withValues(alpha: 0.4)
              : BrandColors.border,
        ),
      ),
      child: Column(
        children: [
          if (widget.plate != null && widget.plate!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.x3, vertical: Spacing.x1),
              decoration: BoxDecoration(
                color: BrandColors.surface2,
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(color: BrandColors.border),
              ),
              child: Text(widget.plate!.toUpperCase(),
                  style: BrandText.mono(size: 14, spacing: 2)),
            ),
          const SizedBox(height: Spacing.x5),
          GestureDetector(
            onTap: s.sending ? null : widget.onTap,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = unlocked ? _pulse.value : 0.0;
                return Container(
                  width: 184,
                  height: 184,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.06 + 0.06 * t),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25 + 0.25 * t),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: unlocked
                            ? BrandColors.primary
                            : BrandColors.surface3,
                        boxShadow: unlocked ? BrandShadows.glow : null,
                      ),
                      child: s.sending
                          ? Center(
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: BrandColors.primaryFg),
                              ),
                            )
                          : Icon(
                              unlocked
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                              size: 56,
                              color: unlocked
                                  ? BrandColors.primaryFg
                                  : BrandColors.foreground,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: Spacing.x5),
          Text(
            s.sending
                ? (s.sendingLabel ?? 'Sending…')
                : (unlocked ? 'Doors unlocked' : 'Doors locked'),
            style: text.headlineSmall,
          ),
          const SizedBox(height: Spacing.x1),
          Text(
            s.sending
                ? 'Contacting the GPS unit…'
                : (unlocked
                    ? 'Tap to lock the car'
                    : 'Tap to unlock the car'),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool ok;
  const _StatTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? BrandColors.success : BrandColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: Spacing.x4, horizontal: Spacing.x2),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: Sizes.icon),
          const SizedBox(height: Spacing.x2),
          valueWidget ??
              Text(value ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: BrandColors.foreground)),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int bars; // 0–4
  const _SignalBars({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final on = i < bars;
        return Container(
          width: 5,
          height: 8.0 + i * 5,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: on ? BrandColors.success : BrandColors.surface3,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final bool online;
  const _ConnectionPill({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? BrandColors.success : BrandColors.destructive;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x3, vertical: Spacing.x2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: Spacing.x2),
          Text(
            online ? 'ONLINE' : 'OFFLINE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  letterSpacing: 1,
                ),
          ),
        ],
      ),
    );
  }
}
