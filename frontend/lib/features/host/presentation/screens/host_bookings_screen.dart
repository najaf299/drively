import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/booking.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/trip_card.dart';
import '../../data/host_service.dart';
import '../../domain/providers/host_provider.dart';

/// Host reservations grouped into Requests / Upcoming / Active / History.
class HostBookingsScreen extends ConsumerWidget {
  const HostBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(hostBookingsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookings'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: BrandColors.primary,
            labelColor: BrandColors.primary,
            unselectedLabelColor: BrandColors.mutedFg,
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: AsyncValueView<List<Booking>>(
          value: bookings,
          onRetry: () => ref.invalidate(hostBookingsProvider),
          data: (list) => TabBarView(
            children: [
              _Tab(
                items: list.where((b) => b.isPending).toList(),
                isRequests: true,
                empty: 'No pending requests',
              ),
              _Tab(
                items: list.where((b) => b.isConfirmed).toList(),
                empty: 'No upcoming bookings',
              ),
              _Tab(
                items: list.where((b) => b.isActive).toList(),
                empty: 'No active trips',
              ),
              _Tab(
                items:
                    list.where((b) => b.isCompleted || b.isCancelled).toList(),
                empty: 'No past bookings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends ConsumerStatefulWidget {
  final List<Booking> items;
  final bool isRequests;
  final String empty;
  const _Tab(
      {required this.items, this.isRequests = false, required this.empty});

  @override
  ConsumerState<_Tab> createState() => _TabState();
}

class _TabState extends ConsumerState<_Tab> {
  String? _busyId;

  Future<void> _approve(Booking b) async {
    setState(() => _busyId = b.id);
    try {
      await ref.read(hostServiceProvider).approveBooking(b.id);
      ref.invalidate(hostBookingsProvider);
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(Booking b) async {
    final reason = await _reasonDialog();
    if (reason == null || reason.isEmpty) return;
    setState(() => _busyId = b.id);
    try {
      await ref.read(hostServiceProvider).declineBooking(b.id, reason);
      ref.invalidate(hostBookingsProvider);
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<String?> _reasonDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline booking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Decline'),
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
    if (widget.items.isEmpty) {
      return ListView(children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        EmptyView(icon: Icons.inbox_outlined, title: widget.empty),
      ]);
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(hostBookingsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(Spacing.x5),
        itemCount: widget.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacing.x3),
        itemBuilder: (_, i) {
          final b = widget.items[i];
          return TripCard(
            booking: b,
            onTap: () => context.push('/bookings/${b.id}'),
            trailing: widget.isRequests
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busyId == b.id ? null : () => _decline(b),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BrandColors.destructive,
                            side: const BorderSide(
                                color: BrandColors.destructive),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: Spacing.x2),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busyId == b.id ? null : () => _approve(b),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}
