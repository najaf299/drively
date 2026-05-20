import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/network/realtime_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/trip_service.dart';
import '../../domain/providers/trip_provider.dart';

/// Live trip view: status, return countdown, host contact and trip actions.
/// Updates over the realtime channel when available, with a 30s REST poll.
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

  @override
  void initState() {
    super.initState();
    // Keep the countdown fresh.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    // REST polling fallback for live status/location.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(tripDetailProvider(widget.tripId));
    });
    // Best-effort realtime updates.
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return car'),
        content:
            const Text('Confirm you have returned the car and ended the trip?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not yet')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End trip')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
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
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text) ?? 0),
            child: const Text('Extend'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Your trip')),
      body: AsyncValueView<Trip>(
        value: trip,
        onRetry: () => ref.invalidate(tripDetailProvider(widget.tripId)),
        data: _content,
      ),
    );
  }

  Widget _content(Trip trip) {
    final returnAt = trip.booking?.returnAt;
    final overdue = trip.isOverdue ||
        (returnAt != null && returnAt.isBefore(DateTime.now()));

    return Column(
      children: [
        _mapPlaceholder(trip),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.x5),
            children: [
              Row(
                children: [
                  StatusChip.trip(trip.status),
                  const Spacer(),
                  if (trip.hasLocation)
                    const Row(
                      children: [
                        Icon(Icons.gps_fixed,
                            size: 14, color: BrandColors.success),
                        SizedBox(width: 4),
                        Text('Live',
                            style: TextStyle(color: BrandColors.success)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: Spacing.x4),
              if (returnAt != null) ...[
                Text(overdue ? 'Trip overdue' : 'Return in',
                    style: TextStyle(
                      color: overdue
                          ? BrandColors.destructive
                          : BrandColors.mutedFg,
                    )),
                const SizedBox(height: Spacing.x1),
                Text(
                  Formatters.countdown(returnAt.difference(DateTime.now())),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: overdue
                        ? BrandColors.destructive
                        : BrandColors.foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: Spacing.x6),
              ],
              if (trip.booking?.car?.host != null) _hostRow(trip),
              const SizedBox(height: Spacing.x6),
              if (trip.isInProgress) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : () => _endTrip(trip),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Return car'),
                ),
                const SizedBox(height: Spacing.x3),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _extend(trip),
                  icon: const Icon(Icons.more_time),
                  label: const Text('Extend trip'),
                ),
              ],
              if (trip.isCompleted)
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/rate/${trip.booking?.id ?? ''}'),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Rate your trip'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hostRow(Trip trip) {
    final host = trip.booking!.car!.host!;
    return Container(
      padding: const EdgeInsets.all(Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: BrandColors.primary),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(host.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Text('Your host',
                    style: TextStyle(color: BrandColors.mutedFg, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _callHost(trip),
            icon: const Icon(Icons.phone_outlined, color: BrandColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _mapPlaceholder(Trip trip) {
    return Container(
      height: 180,
      width: double.infinity,
      color: BrandColors.surface2,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 40, color: BrandColors.primary),
          const SizedBox(height: Spacing.x2),
          Text(
            trip.hasLocation
                ? 'Last seen: ${trip.lastKnownLat!.toStringAsFixed(4)}, '
                    '${trip.lastKnownLng!.toStringAsFixed(4)}'
                : 'Live location unavailable',
            style: const TextStyle(color: BrandColors.mutedFg, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
