import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/wallet.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/wallet_service.dart';
import '../../domain/providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  Future<void> _topUp(BuildContext context, WidgetRef ref) async {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
            children: [
              Row(
                children: [
                  Text('Wallet',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const Spacer(),
                  _CircleAction(
                    icon: Icons.add,
                    onTap: () => _topUp(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x5),
              _BalanceCard(wallet: wallet, name: user?.name ?? 'Drivly member'),
              const SizedBox(height: Spacing.x5),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.add,
                      label: 'Top up',
                      onTap: () => _topUp(context, ref),
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.arrow_outward,
                      label: 'Send',
                      onTap: () => _soon(context),
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.card_giftcard,
                      label: 'Refer',
                      onTap: () => _soon(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x6),
              Text('Activity',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Spacing.x3),
              txns.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(Spacing.x6),
                  child: LoadingView(),
                ),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(walletTransactionsProvider),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: Spacing.x6),
                      child: EmptyView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions yet',
                        subtitle: 'Top up your wallet to get started.',
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final t in list) ...[
                        _TxnTile(txn: t),
                        const SizedBox(height: Spacing.x3),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.primary,
        borderRadius: BorderRadius.circular(Radii.xxl),
        boxShadow: BrandShadows.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Drivly Balance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: BrandColors.primaryFg,
                      )),
              const Spacer(),
              Icon(Icons.account_balance_wallet,
                  color: BrandColors.primaryFg.withValues(alpha: 0.6),
                  size: 22),
            ],
          ),
          const SizedBox(height: Spacing.x4),
          Text(
            balance,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: BrandColors.primaryFg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: Spacing.x6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${name.toUpperCase()}  ••••  8492',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BrandColors.primaryFg.withValues(alpha: 0.85),
                      ),
                ),
              ),
              const SizedBox(width: Spacing.x3),
              Text(
                'drivly.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BrandColors.primaryFg,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.x4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: BrandColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: BrandColors.primary, size: 20),
              ),
              const SizedBox(height: Spacing.x2),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _TxnTile extends StatelessWidget {
  final WalletTransaction txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final credit = txn.isCredit || txn.isRefund;
    final color = credit ? BrandColors.success : BrandColors.destructive;
    final icon = txn.isRefund
        ? Icons.replay
        : credit
            ? Icons.arrow_downward
            : Icons.arrow_upward;
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
            decoration: const BoxDecoration(
              color: BrandColors.surface2,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: BrandColors.mutedFg, size: 20),
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
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Text(
            '${credit ? '+' : '−'}${Formatters.money(txn.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
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
