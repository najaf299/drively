import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/wallet.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/wallet_service.dart';
import '../../domain/providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _topUp(BuildContext context) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      builder: (_) => const _TopUpSheet(),
    );
    if (amount == null) return;
    try {
      await ref.read(walletServiceProvider).topUp(amount);
      ref.invalidate(walletProvider);
      ref.invalidate(walletTransactionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${Formatters.money(amount)}.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Top-up failed.')));
      }
    }
  }

  void _soon(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon.')),
      );

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final txns = ref.watch(walletTransactionsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletProvider);
            ref.invalidate(walletTransactionsProvider);
          },
          child: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, Spacing.x4, Spacing.x5, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page title row
                      Row(
                        children: [
                          Text('Wallet',
                              style:
                                  Theme.of(context).textTheme.headlineLarge),
                          const Spacer(),
                          _CircleAction(
                            icon: Icons.add,
                            onTap: () => _topUp(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.x5),
                      // Hero balance card ~180h surfaceCard gradient
                      _BalanceCard(
                          wallet: wallet,
                          name: user?.name ?? 'Drivly member'),
                      const SizedBox(height: Spacing.x5),
                      // Two CTAs
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _topUp(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Top up'),
                            ),
                          ),
                          const SizedBox(width: Spacing.x3),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _soon(context),
                              icon: const Icon(Icons.arrow_outward, size: 18),
                              label: const Text('Withdraw'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.x5),
                      // Quick-stats row
                      _QuickStatsRow(txns: txns),
                      const SizedBox(height: Spacing.x5),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabs,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
                  isScrollable: false,
                  tabs: const [
                    Tab(text: 'Activity'),
                    Tab(text: 'Cards'),
                    Tab(text: 'Promos'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [
                // Activity tab
                _ActivityTab(txns: txns, onRetry: () {
                  ref.invalidate(walletTransactionsProvider);
                }),
                // Cards tab
                const _ComingSoonTab(icon: Icons.credit_card_outlined, label: 'Saved cards coming soon.'),
                // Promos tab
                const _ComingSoonTab(icon: Icons.local_offer_outlined, label: 'Promos & rewards coming soon.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero balance card ────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final AsyncValue<Wallet> wallet;
  final String name;
  const _BalanceCard({required this.wallet, required this.name});

  @override
  Widget build(BuildContext context) {
    final balance = wallet.maybeWhen(
      data: (w) => Formatters.money(w.balance),
      orElse: () => '—',
    );
    return Container(
      height: 180,
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.xxl),
        boxShadow: BrandShadows.card,
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Available balance',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: BrandColors.mutedFg)),
              const Spacer(),
              const Icon(Icons.account_balance_wallet_outlined,
                  color: BrandColors.mutedFg, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            balance,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: BrandColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: Spacing.x3),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${name.toUpperCase()}  ••••  8492',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BrandColors.mutedFg,
                      ),
                ),
              ),
              const SizedBox(width: Spacing.x3),
              Text(
                'drivly.',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: BrandColors.mutedFg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick stats row ──────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final AsyncValue<List<WalletTransaction>> txns;
  const _QuickStatsRow({required this.txns});

  @override
  Widget build(BuildContext context) {
    final spent = txns.maybeWhen(
      data: (list) {
        final now = DateTime.now();
        return list
            .where((t) =>
                t.isDebit &&
                t.createdAt != null &&
                t.createdAt!.month == now.month &&
                t.createdAt!.year == now.year)
            .fold<double>(0, (s, t) => s + t.amount);
      },
      orElse: () => null,
    );
    final rewards = txns.maybeWhen(
      data: (list) => list
          .where((t) => t.type == 'reward' || t.type == 'referral')
          .fold<double>(0, (s, t) => s + t.amount),
      orElse: () => null,
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Spent this month',
            value: spent != null ? Formatters.money(spent) : '—',
            icon: Icons.arrow_upward,
            iconColor: BrandColors.destructive,
          ),
        ),
        const SizedBox(width: Spacing.x3),
        Expanded(
          child: _StatCard(
            label: 'Rewards earned',
            value: rewards != null ? Formatters.money(rewards) : '—',
            icon: Icons.card_giftcard_outlined,
            iconColor: BrandColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: BrandColors.foreground)),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity tab ─────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  final AsyncValue<List<WalletTransaction>> txns;
  final VoidCallback onRetry;
  const _ActivityTab({required this.txns, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return txns.when(
      loading: () => const Center(child: LoadingView()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: onRetry),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(
                vertical: Spacing.x6, horizontal: Spacing.x5),
            child: EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle: 'Top up your wallet to get started.',
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacing.x3),
          itemBuilder: (_, i) => _TxnTile(txn: list[i]),
        );
      },
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ComingSoonTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: BrandColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: BrandColors.border),
              ),
              child: Icon(icon, color: BrandColors.mutedFg, size: 32),
            ),
            const SizedBox(height: Spacing.x4),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: BrandColors.mutedFg)),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction tile ─────────────────────────────────────────────────────────

class _TxnTile extends StatelessWidget {
  final WalletTransaction txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isRefund = txn.isRefund;
    final isCredit = txn.isCredit || isRefund;
    // Spec: top-up = success arrow-down, charge = destructive arrow-up,
    //        refund = info (replay icon)
    final Color iconColor;
    final IconData icon;
    final Color amountColor;
    if (isRefund) {
      iconColor = BrandColors.info;
      icon = Icons.replay;
      amountColor = BrandColors.info;
    } else if (isCredit) {
      iconColor = BrandColors.success;
      icon = Icons.arrow_downward;
      amountColor = BrandColors.success;
    } else {
      iconColor = BrandColors.destructive;
      icon = Icons.arrow_upward;
      amountColor = BrandColors.destructive;
    }

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
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description ?? _humanise(txn.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (txn.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(Formatters.date(txn.createdAt!),
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Text(
            '${isCredit ? '+' : '−'}${Formatters.money(txn.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }

  static String _humanise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ─── Circle action button ─────────────────────────────────────────────────────

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: const CircleBorder(side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: BrandColors.foreground, size: 22),
        ),
      ),
    );
  }
}

// ─── Top-up bottom sheet ──────────────────────────────────────────────────────

class _TopUpSheet extends StatelessWidget {
  const _TopUpSheet();

  @override
  Widget build(BuildContext context) {
    const amounts = [10.0, 25.0, 50.0, 100.0];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top up wallet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.x4),
            Wrap(
              spacing: Spacing.x3,
              runSpacing: Spacing.x3,
              children: amounts
                  .map((a) => SizedBox(
                        width: 100,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, a),
                          child: Text(Formatters.money(a)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: Spacing.x4),
          ],
        ),
      ),
    );
  }
}
