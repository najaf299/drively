import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/wallet.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final txns = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar:
          AppBar(title: const Text('Wallet'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletProvider);
          ref.invalidate(walletTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(Spacing.x5),
          children: [
            _balanceCard(context, ref, wallet),
            const SizedBox(height: Spacing.x6),
            Text('Recent activity',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.x2),
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
                  children: list.map((t) => _TxnTile(txn: t)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(
      BuildContext context, WidgetRef ref, AsyncValue<Wallet> wallet) {
    return Container(
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
          const Text('Available balance',
              style: TextStyle(color: BrandColors.primaryFg)),
          const SizedBox(height: Spacing.x2),
          Text(
            wallet.maybeWhen(
              data: (w) => Formatters.money(w.balance),
              orElse: () => '—',
            ),
            style: const TextStyle(
              color: BrandColors.primaryFg,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: Spacing.x4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _topUp(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandColors.primaryFg,
                    side: const BorderSide(color: BrandColors.primaryFg),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Top up'),
                ),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Withdrawals coming soon.')),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandColors.primaryFg,
                    side: const BorderSide(color: BrandColors.primaryFg),
                  ),
                  icon: const Icon(Icons.arrow_outward),
                  label: const Text('Withdraw'),
                ),
              ),
            ],
          ),
        ],
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
    final color = txn.isRefund
        ? BrandColors.accent
        : credit
            ? BrandColors.success
            : BrandColors.destructive;
    final icon = txn.isRefund
        ? Icons.replay
        : credit
            ? Icons.arrow_downward
            : Icons.arrow_upward;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(txn.description ?? _humanise(txn.type)),
      subtitle: txn.createdAt != null
          ? Text(Formatters.date(txn.createdAt!),
              style: const TextStyle(color: BrandColors.mutedFg, fontSize: 12))
          : null,
      trailing: Text(
        '${credit ? '+' : '-'}${Formatters.money(txn.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
