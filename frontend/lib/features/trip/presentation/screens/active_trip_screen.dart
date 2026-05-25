import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/network/realtime_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/trip_service.dart';
import '../../domain/providers/gps_device_provider.dart';
import '../../domain/providers/trip_provider.dart';

/// Live trip view: map, timer/ETA, host contact, unlock + end trip actions.
/// Spec §7.18 — realtime + 30 s polling preserved.
class ActiveTripScreen extends ConsumerStatefulWidget {
  final String tripId;
  const ActiveTripScreen({super.key, required this.tripId});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  Timer? _poll;
  Timer? _tick;
  StreamSubscription<RealtimeEvent>? _rt;
  bool _busy = false;
  bool _autoUnlocked = false; // unlock the car once when the trip is live

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(tripDetailProvider(widget.tripId));
    });
    final client = ref.read(realtimeClientProvider);
    client.subscribePrivate('trip.${widget.tripId}');
    _rt = client.events.listen((event) {
      if (event.channel.contains(widget.tripId)) {
        ref.invalidate(tripDetailProvider(widget.tripId));
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    _rt?.cancel();
    ref.read(realtimeClientProvider).unsubscribe('trip.${widget.tripId}');
    super.dispose();
  }

  Future<void> _endTrip(Trip trip) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Return car',
      message: 'Confirm you have returned the car and ended the trip?',
      confirmLabel: 'End trip',
      destructive: true,
    );
    if (!confirm) return;
    setState(() => _busy = true);
    try {
      // Lock the car on return — the closing half of the GPS lock lifecycle.
      final device = ref.read(gpsDeviceProvider(trip.id).notifier);
      if (!ref.read(gpsDeviceProvider(trip.id)).locked) {
        await device.lock();
      }
      await ref.read(tripServiceProvider).end(trip.id);
      final bookingId = trip.booking?.id;
      if (mounted) {
        if (bookingId != null) {
          context.go('/rate/$bookingId');
        } else {
          context.go('/trips');
        }
      }
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _extend(Trip trip) async {
    final controller = TextEditingController(text: '1');
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Extend trip'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Extra days'),
        ),
        actionsPadding: kDialogActionsPadding,
        actions: [
          DialogActions(
            confirmLabel: 'Extend',
            onCancel: () => Navigator.pop(ctx),
            onConfirm: () =>
                Navigator.pop(ctx, int.tryParse(controller.text) ?? 0),
          ),
        ],
      ),
    );
    if (days == null || days < 1) return;
    setState(() => _busy = true);
    try {
      await ref.read(tripServiceProvider).extend(trip.id, days);
      ref.invalidate(tripDetailProvider(widget.tripId));
      _snack('Trip extended by ${Formatters.plural(days, 'day')}.');
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _callHost(Trip trip) async {
    final phone = trip.booking?.car?.host?.phone;
    if (phone == null || phone.isEmpty) {
      _snack('Host phone number is not available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripDetailProvider(widget.tripId));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: AsyncValueView<Trip>(
            value: trip,
            onRetry: () => ref.invalidate(tripDetailProvider(widget.tripId)),
            data: _content,
          ),
        ),
      ),
    );
  }

  Widget _content(Trip trip) {
    final car = trip.booking?.car;
    final from = trip.booking?.pickupAddress ?? car?.city;
    final to = car?.city;

    // Once the trip is live (paid + started), unlock the car automatically —
    // the opening half of the GPS lock lifecycle.
    if (trip.isInProgress && !_autoUnlocked) {
      _autoUnlocked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final device = ref.read(gpsDeviceProvider(trip.id).notifier);
        device.seed(lat: car?.lat, lng: car?.lng);
        if (ref.read(gpsDeviceProvider(trip.id)).locked) device.unlock();
      });
    }

    return Column(
      children: [
        // App bar row
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x2),
          child: Row(
            children: [
              _circleBack(),
              const SizedBox(width: Spacing.x3),
              Text(
                'Active trip',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              // Live indicator — spec §7.18: destructive tonal.
              const StatusBadge('LIVE',
                  tone: BadgeTone.live, icon: Icons.circle),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x2, Spacing.x5, Spacing.x4),
            children: [
              _mapCard(trip),
              const SizedBox(height: Spacing.x4),
              _carCard(trip, from, to),
              const SizedBox(height: Spacing.x4),
              _gpsControlCard(trip),
              const SizedBox(height: Spacing.x4),
              // Host contact + quick-action row
              Row(
                children: [
                  Expanded(
                    child: _actionTile(
                      Icons.call_outlined,
                      'Call host',
                      onTap: () => _callHost(trip),
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: _actionTile(
                      Icons.photo_camera_outlined,
                      'Photos',
                      onTap: () => AppSnack.soon(context),
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: _actionTile(
                      Icons.support_agent_outlined,
                      'Support',
                      onTap: () => AppSnack.soon(context),
                    ),
                  ),
                ],
              ),
              if (trip.isInProgress) ...[
                const SizedBox(height: Spacing.x4),
                // Extend trip — tonal outlined button
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _extend(trip),
                  icon: const Icon(Icons.more_time),
                  label: const Text('Extend trip'),
                ),
              ],
              if (trip.isCompleted) ...[
                const SizedBox(height: Spacing.x4),
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/rate/${trip.booking?.id ?? ''}'),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Rate your trip'),
                ),
              ],
            ],
          ),
        ),
        // Sticky 'End trip' — spec: BrandColors.destructive filled button.
        if (trip.isInProgress)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, 0, Spacing.x5, Spacing.x4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.pill),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.destructive.withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _busy ? null : () => _endTrip(trip),
                style: FilledButton.styleFrom(
                  backgroundColor: BrandColors.destructive,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      BrandColors.destructive.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('End trip'),
              ),
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

  Widget _mapCard(Trip trip) {
    final hasLoc = trip.hasLocation;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.xl),
      child: Container(
        height: 220,
        color: BrandColors.surface2,
        child: Stack(
          children: [
            // Lime route polyline.
            Positioned.fill(
              child: CustomPaint(painter: _RoutePainter()),
            ),
            // ETA chip — surface@80 + primary clock icon, spec §7.18.
            Positioned(
              left: Spacing.x4,
              top: Spacing.x4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.x3, vertical: Spacing.x2),
                decoration: BoxDecoration(
                  color: BrandColors.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(color: BrandColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 16, color: BrandColors.primary),
                    const SizedBox(width: Spacing.x2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ETA 18 min',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        Text(
                          'Trip in progress · 12.4 km',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // User location dot — spec: primary colour.
            Positioned(
              right: Spacing.x4,
              bottom: Spacing.x4,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BrandColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.navigation_outlined,
                    color: BrandColors.primaryFg),
              ),
            ),
            if (!hasLoc)
              Positioned(
                left: Spacing.x4,
                bottom: Spacing.x4,
                child: Text(
                  'Live location unavailable',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: BrandColors.mutedFg),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Opens the GPS car-control screen, seeding it with this trip's context.
  void _openGps(Trip trip) {
    final car = trip.booking?.car;
    context.push('/gps/${trip.id}', extra: {
      'lat': trip.lastKnownLat,
      'lng': trip.lastKnownLng,
      'carName': car?.displayNameWithYear,
      'plate': car?.plateNumber,
    });
  }

  /// Prominent entry point to the connected-car controls (lock/unlock/GPS).
  Widget _gpsControlCard(Trip trip) {
    final gps = ref.watch(gpsDeviceProvider(trip.id));
    final unlocked = !gps.locked;
    final accent = unlocked ? BrandColors.primary : BrandColors.foreground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openGps(trip),
        borderRadius: BorderRadius.circular(Radii.xl),
        child: Container(
          padding: const EdgeInsets.all(Spacing.x4),
          decoration: BoxDecoration(
            gradient: BrandGradients.surfaceCard,
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(
              color: unlocked
                  ? BrandColors.primary.withValues(alpha: 0.4)
                  : BrandColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: Sizes.avatarMd,
                height: Sizes.avatarMd,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(
                  unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Car control',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      unlocked
                          ? 'Doors unlocked · tap to manage'
                          : 'Doors locked · tap to unlock',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: BrandColors.mutedFg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carCard(Trip trip, String? from, String? to) {
    final car = trip.booking?.car;
    final name = car?.displayNameWithYear ?? 'Your car';
    final route = (from != null && to != null) ? '$from → $to' : (from ?? to);
    final unlocked = !ref.watch(gpsDeviceProvider(trip.id)).locked;
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                if (route != null && route.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    route,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.x3),
          StatusBadge(
            unlocked ? 'UNLOCKED' : 'LOCKED',
            tone: unlocked ? BadgeTone.success : BadgeTone.neutral,
            icon: unlocked ? Icons.lock_open : Icons.lock,
          ),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, {VoidCallback? onTap}) {
    return Material(
      color: BrandColors.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.x4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: BrandColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: BrandColors.primary, size: Sizes.icon),
              const SizedBox(height: Spacing.x2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decorative lime route polyline drawn across the map card.
/// End dot is now primary (spec: user dot = primary, no accent).
class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BrandColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.82)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.6,
        size.width * 0.45,
        size.height * 0.7,
        size.width * 0.6,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.26,
        size.width * 0.8,
        size.height * 0.32,
        size.width * 0.9,
        size.height * 0.2,
      );
    canvas.drawPath(path, paint);

    // Both dots: primary (spec: user dot = primary, no coral/accent).
    final dot = Paint()..color = BrandColors.primary;
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.82), 6, dot);
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.2),
      6,
      dot,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
