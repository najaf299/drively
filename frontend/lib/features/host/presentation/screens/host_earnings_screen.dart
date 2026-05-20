import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/earning.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/providers/host_provider.dart';

/// Host earnings: period summary + per-booking payout history.
/// Restyled to the Drivly dark premium system.
class HostEarningsScreen extends ConsumerStatefulWidget {
  const HostEarningsScreen({super.key});

  @override
  ConsumerState<HostEarningsScreen> createState() => _HostEarningsScreenState();
}

class _HostEarningsScreenState extends ConsumerState<HostEarningsScreen> {
  String _period = 'month';

  static const _periods = {'week': 'Week', 'month': 'Month', 'year': 'Year'};

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(hostEarningsProvider(_period));
    final history = ref.watch(hostEarningsHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x4),
              child: Row(
                children: [
                  _CircleBackButton(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/host'),
                  ),
                  const SizedBox(width: Spacing.x4),
                  Expanded(
                    child: Text('Earnings',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, 0, Spacing.x5, Spacing.x10),
                children: [
                  _PeriodSelector(
                    periods: _periods,
                    selected: _period,
                    onChanged: (p) => setState(() => _period = p),
                  ),
                  const SizedBox(height: Spacing.x5),
                  summary.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(Spacing.x6),
                      child: LoadingView(),
                    ),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () =>
                          ref.invalidate(hostEarningsProvider(_period)),
                    ),
                    data: (s) => _summaryCard(s),
                  ),
                  const SizedBox(height: Spacing.x6),
                  Text('Payout history',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: Spacing.x3),
                  history.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(Spacing.x6),
                      child: LoadingView(),
                    ),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () =>
                          ref.invalidate(hostEarningsHistoryProvider),
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
                        children: [
                          for (final e in list) ...[
                            _earningTile(e),
                            const SizedBox(height: Spacing.x3),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(EarningsSummary s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.primary,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: BrandShadows.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net earnings · ${_periods[_period]}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: BrandColors.primaryFg,
                  )),
          const SizedBox(height: Spacing.x3),
          Text(
            Formatters.money(s.total),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: BrandColors.primaryFg,
                ),
          ),
          if (s.gross > 0) ...[
            const SizedBox(height: Spacing.x4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.x3, vertical: Spacing.x2),
              decoration: BoxDecoration(
                color: BrandColors.primaryFg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Text(
                'Gross ${Formatters.money(s.gross)}  ·  '
                'Commission ${Formatters.money(s.commission)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BrandColors.primaryFg.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _earningTile(Earning e) {
    final statusColor = e.isPaid ? BrandColors.success : BrandColors.warning;
    return Container(
      padding: const EdgeInsets.all(Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: Sizes.avatar,
            height: Sizes.avatar,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              e.isPaid ? Icons.check : Icons.schedule,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.booking?.car?.displayNameWithYear ?? 'Trip earning',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                StatusBadge(
                  e.isPaid ? 'PAID' : 'PENDING',
                  tone: e.isPaid ? BadgeTone.success : BadgeTone.warning,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.money(e.netAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BrandColors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (e.createdAt != null) ...[
                const SizedBox(height: 2),
                Text(Formatters.date(e.createdAt!),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Segmented period selector styled to the dark premium system.
class _PeriodSelector extends StatelessWidget {
  final Map<String, String> periods;
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
    required this.periods,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: periods.entries.map((e) {
          final active = e.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? BrandColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  e.value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: active
                            ? BrandColors.primaryFg
                            : BrandColors.mutedFg,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.border),
        ),
        child: const Icon(Icons.chevron_left,
            color: BrandColors.foreground, size: Sizes.iconLg),
      ),
    );
  }
}
