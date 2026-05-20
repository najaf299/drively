import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/earning.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/providers/host_provider.dart';

/// Host earnings: period summary + per-booking payout history.
class HostEarningsScreen extends ConsumerStatefulWidget {
  const HostEarningsScreen({super.key});

  @override
  ConsumerState<HostEarningsScreen> createState() => _HostEarningsScreenState();
}

class _HostEarningsScreenState extends ConsumerState<HostEarningsScreen> {
  String _period = 'month';

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(hostEarningsProvider(_period));
    final history = ref.watch(hostEarningsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.x5),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'week', label: Text('Week')),
              ButtonSegment(value: 'month', label: Text('Month')),
              ButtonSegment(value: 'year', label: Text('Year')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
          const SizedBox(height: Spacing.x5),
          summary.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Spacing.x6),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(hostEarningsProvider(_period)),
            ),
            data: (s) => _summaryCard(s),
          ),
          const SizedBox(height: Spacing.x6),
          Text('Payout history',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.x2),
          history.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Spacing.x6),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(hostEarningsHistoryProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: Spacing.x6),
                  child: EmptyView(
                    icon: Icons.payments_outlined,
                    title: 'No earnings yet',
                    subtitle: 'Earnings appear after completed trips.',
                  ),
                );
              }
              return Column(
                children: list.map(_earningTile).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(EarningsSummary s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BrandColors.primary, BrandColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net earnings · $_period',
              style: const TextStyle(color: BrandColors.primaryFg)),
          const SizedBox(height: Spacing.x2),
          Text(
            Formatters.money(s.total),
            style: const TextStyle(
              color: BrandColors.primaryFg,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (s.gross > 0) ...[
            const SizedBox(height: Spacing.x3),
            Text(
              'Gross ${Formatters.money(s.gross)} · '
              'Commission ${Formatters.money(s.commission)}',
              style: TextStyle(
                  color: BrandColors.primaryFg.withValues(alpha: 0.85),
                  fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _earningTile(Earning e) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (e.isPaid ? BrandColors.success : BrandColors.warning)
            .withValues(alpha: 0.15),
        child: Icon(
          e.isPaid ? Icons.check : Icons.schedule,
          color: e.isPaid ? BrandColors.success : BrandColors.warning,
          size: 20,
        ),
      ),
      title: Text(
        e.booking?.car?.displayNameWithYear ?? 'Trip earning',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        e.createdAt != null ? Formatters.date(e.createdAt!) : e.status,
        style: const TextStyle(color: BrandColors.mutedFg, fontSize: 12),
      ),
      trailing: Text(
        Formatters.money(e.netAmount),
        style: const TextStyle(
            color: BrandColors.success, fontWeight: FontWeight.w700),
      ),
    );
  }
}
