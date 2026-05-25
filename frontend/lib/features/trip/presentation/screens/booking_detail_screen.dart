import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../booking/data/booking_service.dart';
import '../../../booking/domain/providers/booking_provider.dart';
import '../../data/trip_service.dart';

/// Booking detail — spec §7.17 (trip detail).
/// Status banner · map preview · timeline · host contact · trip code ·
/// price breakdown · action buttons.
class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _busy = false;

  Future<void> _startTrip(Booking booking) async {
    setState(() => _busy = true);
    try {
      final trip = await ref.read(tripServiceProvider).start(booking.id);
      if (mounted) unawaited(context.push('/trip/${trip.id}'));
      ref.invalidate(bookingDetailProvider(widget.bookingId));
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(Booking booking) async {
    final reason =
        await _reasonDialog('Cancel booking', 'Reason for cancelling');
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(bookingServiceProvider).cancel(booking.id, reason);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(bookingsProvider);
      _snack('Booking cancelled.');
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _callHost(Booking booking) async {
    final phone = booking.car?.host?.phone;
    if (phone == null || phone.isEmpty) {
      _snack('Host phone number is not available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snack('Could not start a call.');
    }
  }

  Future<String?> _reasonDialog(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actionsPadding: kDialogActionsPadding,
        actions: [
          DialogActions(
            confirmLabel: 'Confirm',
            onCancel: () => Navigator.pop(ctx),
            onConfirm: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingDetailProvider(widget.bookingId));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: AsyncValueView<Booking>(
            value: booking,
            onRetry: () =>
                ref.invalidate(bookingDetailProvider(widget.bookingId)),
            data: (b) => _content(b),
          ),
        ),
      ),
    );
  }

  Widget _content(Booking b) {
    final car = b.car;
    return Column(
      children: [
        // Header
        Padding(
          padding:
              const EdgeInsets.fromLTRB(Spacing.x5, Spacing.x3, Spacing.x5, 0),
          child: Row(
            children: [
              _circleBack(),
              const SizedBox(width: Spacing.x3),
              Text('Booking',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              _statusBadge(b),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x5),
            children: [
              // Status banner — warning if action needed (confirmed → start).
              if (b.isConfirmed) _statusBanner(b),
              if (b.isConfirmed) const SizedBox(height: Spacing.x4),

              // Car summary card
              if (car != null) _carCard(car),
              if (car != null) const SizedBox(height: Spacing.x4),

              // Timeline
              _timeline(b),
              const SizedBox(height: Spacing.x4),

              // Host contact row
              _hostContactRow(b),
              const SizedBox(height: Spacing.x4),

              // Trip code card
              _tripCodeCard(b),
              const SizedBox(height: Spacing.x4),

              // Price breakdown
              _priceCard(b),
              const SizedBox(height: Spacing.x6),

              // Action buttons
              ..._actions(b),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Status banner ──────────────────────────────────────────────────────────

  Widget _statusBanner(Booking b) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4, vertical: Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.warningBg,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: BrandColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: Sizes.iconSm, color: BrandColors.warning),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Text(
              'Your trip is confirmed. Tap "Start trip" when you arrive at the vehicle.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: BrandColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Car card ───────────────────────────────────────────────────────────────

  Widget _carCard(dynamic car) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          AppNetworkImage(
            url: car.coverPhotoUrl,
            width: 72,
            height: 72,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.displayNameWithYear,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(car.city, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline ───────────────────────────────────────────────────────────────

  /// Vertical timeline: Booked · Pickup · Return · Completed.
  /// Dots are primary when reached, border when pending; connected line.
  Widget _timeline(Booking b) {
    final steps = [
      _TimelineStep(
        label: 'Booked',
        sub: b.createdAt != null ? Formatters.date(b.createdAt!) : null,
        reached: true,
      ),
      _TimelineStep(
        label: 'Pickup',
        sub: b.pickupAt != null ? Formatters.dateTime(b.pickupAt!) : null,
        reached: b.isActive || b.isCompleted,
      ),
      _TimelineStep(
        label: 'Return',
        sub: b.returnAt != null ? Formatters.dateTime(b.returnAt!) : null,
        reached: b.isCompleted,
      ),
      _TimelineStep(
        label: 'Completed',
        sub: null,
        reached: b.isCompleted,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trip timeline', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.x4),
          for (var i = 0; i < steps.length; i++)
            _timelineItem(steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }

  Widget _timelineItem(_TimelineStep step, {required bool isLast}) {
    const dotSize = 14.0;
    final reached = step.reached;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: dotSize + 2,
          child: Column(
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: reached ? BrandColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: reached
                        ? BrandColors.primary
                        : BrandColors.borderStrong,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  color: reached
                      ? BrandColors.primary.withValues(alpha: 0.4)
                      : BrandColors.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.x3),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Spacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: reached
                              ? BrandColors.foreground
                              : BrandColors.mutedFg,
                        )),
                if (step.sub != null) ...[
                  const SizedBox(height: 2),
                  Text(step.sub!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Host contact row ────────────────────────────────────────────────────

  Widget _hostContactRow(Booking b) {
    final host = b.car?.host;
    if (host == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          // Avatar fallback
          Container(
            width: Sizes.avatarMd,
            height: Sizes.avatarMd,
            decoration: BoxDecoration(
              color: BrandColors.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(host.name),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(host.name, style: Theme.of(context).textTheme.titleSmall),
                Text('Host', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          // 44-dp tonal icon buttons — spec §7.17.
          _iconRoundButton(Icons.call_outlined, onTap: () => _callHost(b)),
          const SizedBox(width: Spacing.x2),
          _iconRoundButton(
            Icons.chat_bubble_outline,
            onTap: () => context.push(
              '/chat/new',
              extra: {
                'recipientId': host.id,
                'name': host.name,
                'bookingId': b.id,
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconRoundButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: BrandColors.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: Sizes.iconRoundButton,
          height: Sizes.iconRoundButton,
          child: Icon(icon, size: Sizes.iconSm, color: BrandColors.foreground),
        ),
      ),
    );
  }

  // ─── Trip code card ──────────────────────────────────────────────────────

  Widget _tripCodeCard(Booking b) {
    final code = b.reference.length >= 6
        ? b.reference.substring(0, 6).toUpperCase()
        : b.reference.toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: Spacing.x5, horizontal: Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        children: [
          Text(
            code,
            textAlign: TextAlign.center,
            style: BrandText.mono(size: 36, spacing: 6),
          ),
          const SizedBox(height: Spacing.x2),
          Text(
            'Show to host at pickup',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: BrandColors.mutedFg),
          ),
        ],
      ),
    );
  }

  // ─── Status badge ────────────────────────────────────────────────────────

  StatusBadge _statusBadge(Booking b) {
    if (b.isActive) {
      return const StatusBadge('Active', tone: BadgeTone.live);
    }
    if (b.isCompleted) {
      return const StatusBadge('Completed', tone: BadgeTone.success);
    }
    if (b.isCancelled) {
      return const StatusBadge('Cancelled', tone: BadgeTone.error);
    }
    if (b.isPending) {
      return const StatusBadge('Pending', tone: BadgeTone.warning);
    }
    return const StatusBadge('Confirmed', tone: BadgeTone.neutral);
  }

  // ─── Price card ──────────────────────────────────────────────────────────

  Widget _priceCard(Booking b) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price breakdown',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.x3),
          _priceRow('Subtotal', b.pricing.subtotal),
          if (b.pricing.serviceFee > 0)
            _priceRow('Service fee', b.pricing.serviceFee),
          if (b.pricing.tax > 0) _priceRow('Tax', b.pricing.tax),
          if (b.pricing.discount > 0)
            _priceRow('Discount', -b.pricing.discount,
                valueColor: BrandColors.primary),
          const Divider(height: Spacing.x6),
          _priceRow('Total', b.pricing.totalAmount, bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount,
      {bool bold = false, Color? valueColor}) {
    final t = Theme.of(context).textTheme;
    final labelStyle = bold
        ? t.titleMedium
        : t.bodyMedium?.copyWith(color: BrandColors.mutedFg);
    final valueStyle = bold
        ? t.headlineMedium?.copyWith(color: BrandColors.primary)
        : t.bodyMedium?.copyWith(
            color: valueColor ?? BrandColors.foreground,
            fontWeight: FontWeight.w500,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(Formatters.money(amount), style: valueStyle),
        ],
      ),
    );
  }

  // ─── Circle back ────────────────────────────────────────────────────────

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

  // ─── Action buttons ──────────────────────────────────────────────────────

  List<Widget> _actions(Booking b) {
    final widgets = <Widget>[];

    if (b.isActive && b.trip != null) {
      widgets.add(_primaryButton(
        'View live trip',
        icon: Icons.navigation_outlined,
        onPressed: () => context.push('/trip/${b.trip!.id}'),
      ));
    } else if (b.isConfirmed) {
      widgets.add(_primaryButton(
        'Start trip',
        loading: _busy,
        onPressed: _busy ? null : () => _startTrip(b),
      ));
    } else if (b.isCompleted && b.canReview) {
      widgets.add(_primaryButton(
        'Rate your trip',
        icon: Icons.star_outline,
        onPressed: () => context.push('/rate/${b.id}'),
      ));
    }

    // Extend trip — tonal
    if (b.isActive) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: Spacing.x3));
      widgets.add(OutlinedButton.icon(
        onPressed: _busy ? null : () {},
        icon: const Icon(Icons.more_time),
        label: const Text('Extend trip'),
      ));
    }

    // Cancel — destructive ghost
    if (b.canCancel) {
      widgets.add(const SizedBox(height: Spacing.x2));
      widgets.add(OutlinedButton(
        onPressed: _busy ? null : () => _cancel(b),
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.destructive,
          side: BorderSide(color: BrandColors.destructive),
        ),
        child: const Text('Cancel trip'),
      ));
    }

    // Report — link style
    widgets.add(const SizedBox(height: Spacing.x2));
    widgets.add(TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(foregroundColor: BrandColors.mutedFg),
      child: const Text('Report an issue'),
    ));

    return widgets;
  }

  Widget _primaryButton(
    String label, {
    IconData? icon,
    bool loading = false,
    VoidCallback? onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: BrandColors.primaryFg))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Simple data class for a timeline step.
class _TimelineStep {
  final String label;
  final String? sub;
  final bool reached;
  const _TimelineStep(
      {required this.label, required this.sub, required this.reached});
}
