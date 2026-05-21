import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/earning.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/providers/host_provider.dart';

/// Host earnings — spec §7.37.
///
/// Period segmented (Week / Month / Year). Summary card uses surfaceCard
/// gradient. KPI row 3: Gross · Service fee · Net. Bar chart in primary
/// (insight accents may use accent purple). Trip list with payout AED right.
class HostEarningsScreen extends ConsumerStatefulWidget {
  const HostEarningsScreen({super.key});

  @override
  ConsumerState<HostEarningsScreen> createState() =>
      _HostEarningsScreenState();
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
                        style:
                            Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, 0, Spacing.x5, Spacing.x10),
                children: [
                  // Period segmented tabs
                  _PeriodSelector(
                    periods: _periods,
                    selected: _period,
                    onChanged: (p) => setState(() => _period = p),
                  ),
                  const SizedBox(height: Spacing.x5),
                  // Summary card
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
                    data: (s) => _SummaryCard(
                        summary: s, period: _periods[_period] ?? _period),
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
                          padding:
                              EdgeInsets.symmetric(vertical: Spacing.x6),
                          child: EmptyView(
                            icon: Icons.payments_outlined,
                            title: 'No earnings yet',
                            subtitle:
                                'Earnings appear after completed trips.',
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final e in list) ...[
                            _EarningTile(earning: e),
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
}

// ─── Summary card (surfaceCard gradient, KPI row 3) ───────────────────────────

class _SummaryCard extends StatelessWidget {
  final EarningsSummary summary;
  final String period;
  const _SummaryCard({required this.summary, required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: BrandShadows.card,
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net earnings · $period',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: BrandColors.mutedFg),
          ),
          const SizedBox(height: Spacing.x3),
          // Net earnings — headlineLarge in primary per spec
          Text(
            Formatters.money(summary.total),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: BrandColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: Spacing.x5),
          // KPI row 3: Gross · Service fee · Net
          Row(
            children: [
              Expanded(
                child: _KpiCell(
                  label: 'Gross',
                  value: Formatters.money(summary.gross),
                ),
              ),
              _KpiDivider(),
              Expanded(
                child: _KpiCell(
                  label: 'Service fee',
                  value: Formatters.money(summary.commission),
                  valueColor: BrandColors.destructive,
                ),
              ),
              _KpiDivider(),
              Expanded(
                child: _KpiCell(
                  label: 'Net',
                  value: Formatters.money(summary.net),
                  valueColor: BrandColors.success,
                ),
              ),
            ],
          ),
          if (summary.tripsCount > 0) ...[
            const SizedBox(height: Spacing.x4),
            // Simple bar chart placeholder — bars in primary, accent for insight
            _BarChartPlaceholder(tripsCount: summary.tripsCount),
          ],
        ],
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _KpiCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor ?? BrandColors.foreground,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: BrandColors.mutedFg),
        ),
      ],
    );
  }
}

class _KpiDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: BrandColors.border,
      margin: const EdgeInsets.symmetric(horizontal: Spacing.x2),
    );
  }
}

/// Simple bar chart placeholder — bars in primary, last bar accent (purple).
class _BarChartPlaceholder extends StatelessWidget {
  final int tripsCount;
  const _BarChartPlaceholder({required this.tripsCount});

  static const _barHeights = [0.4, 0.6, 0.5, 0.8, 0.55, 0.7, 0.9];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barHeights.length, (i) {
          final isLast = i == _barHeights.length - 1;
          // Insight accent on last bar per spec
          final color = isLast ? BrandColors.accent : BrandColors.primary;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FractionallySizedBox(
                alignment: Alignment.bottomCenter,
                heightFactor: _barHeights[i],
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isLast ? 0.8 : 0.5),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Earning trip tile ────────────────────────────────────────────────────────

class _EarningTile extends StatelessWidget {
  final Earning earning;
  const _EarningTile({required this.earning});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        earning.isPaid ? BrandColors.success : BrandColors.warning;
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
              earning.isPaid ? Icons.check : Icons.schedule,
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
                  earning.booking?.car?.displayNameWithYear ?? 'Trip earning',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                StatusBadge(
                  earning.isPaid ? 'Paid' : 'Pending',
                  tone: earning.isPaid
                      ? BadgeTone.success
                      : BadgeTone.warning,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x3),
          // Payout AED right-aligned
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.money(earning.netAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BrandColors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (earning.createdAt != null) ...[
                const SizedBox(height: 2),
                Text(Formatters.date(earning.createdAt!),
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Period selector ──────────────────────────────────────────────────────────

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

// ─── Circle back button ───────────────────────────────────────────────────────

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
