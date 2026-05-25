import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/wallet.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/wallet_service.dart';
import '../../domain/providers/payment_methods_provider.dart';
import '../../domain/providers/promos_provider.dart';
import '../../domain/providers/wallet_provider.dart';
import '../widgets/add_card_sheet.dart';
import 'payment_methods_screen.dart' show DottedBorderBox;

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
      useRootNavigator: true,
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
                const _CardsTab(),
                // Promos tab
                const _PromosTab(),
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
              Icon(Icons.account_balance_wallet_outlined,
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

// ─── Cards tab ─────────────────────────────────────────────────────────────

class _CardsTab extends ConsumerWidget {
  const _CardsTab();

  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const AddCardSheet(),
    );
    if (added == true && context.mounted) {
      AppSnack.success(context, 'Card added.');
    }
  }

  void _cardMenu(BuildContext context, WidgetRef ref, SavedCard card) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!card.isDefault)
              ListTile(
                leading: Icon(Icons.star_outline,
                    color: BrandColors.primary),
                title: const Text('Set as default'),
                onTap: () {
                  ref.read(savedCardsProvider.notifier).setDefault(card.id);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: BrandColors.destructive),
              title: const Text('Remove card'),
              onTap: () {
                ref.read(savedCardsProvider.notifier).remove(card.id);
                Navigator.pop(context);
                AppSnack.show(context, 'Card removed.',
                    type: SnackType.info);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(savedCardsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
      children: [
        for (final card in cards) ...[
          _WalletCardRow(
            card: card,
            onMenu: () => _cardMenu(context, ref, card),
          ),
          const SizedBox(height: Spacing.x3),
        ],
        const SizedBox(height: Spacing.x2),
        _DashedAddTile(
          label: 'Add payment method',
          onTap: () => _addCard(context, ref),
        ),
        const SizedBox(height: Spacing.x4),
        Row(
          children: [
            Icon(Icons.lock_outline,
                size: Sizes.iconSm, color: BrandColors.mutedFg),
            const SizedBox(width: Spacing.x2),
            Expanded(
              child: Text(
                'Cards are encrypted and tokenised by Stripe. We never store '
                'full card numbers.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalletCardRow extends StatelessWidget {
  final SavedCard card;
  final VoidCallback onMenu;
  const _WalletCardRow({required this.card, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x5, vertical: Spacing.x3),
      decoration: BoxDecoration(
        gradient: BrandGradients.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
        boxShadow: BrandShadows.card,
      ),
      child: Row(
        children: [
          _CardBrandMark(brand: card.brand),
          const SizedBox(width: Spacing.x4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•••• ${card.lastFour}',
                    style: BrandText.mono(size: 17, spacing: 2)),
                const SizedBox(height: 4),
                Text('Exp ${card.expiry}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (card.isDefault) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.x3, vertical: Spacing.x1),
              decoration: BoxDecoration(
                color: BrandColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text('Default',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: BrandColors.success, letterSpacing: 0.4)),
            ),
            const SizedBox(width: Spacing.x1),
          ],
          IconButton(
            onPressed: onMenu,
            icon: Icon(Icons.more_vert, color: BrandColors.mutedFg),
          ),
        ],
      ),
    );
  }
}

class _CardBrandMark extends StatelessWidget {
  final String brand;
  const _CardBrandMark({required this.brand});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (brand.toLowerCase()) {
      'visa' => (Icons.credit_card, BrandColors.info),
      'mastercard' => (Icons.credit_card, BrandColors.warning),
      'amex' => (Icons.credit_card, BrandColors.success),
      _ => (Icons.credit_card, BrandColors.mutedFg),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: Sizes.icon),
    );
  }
}

// ─── Promos tab ────────────────────────────────────────────────────────────

class _PromosTab extends ConsumerStatefulWidget {
  const _PromosTab();

  @override
  ConsumerState<_PromosTab> createState() => _PromosTabState();
}

class _PromosTabState extends ConsumerState<_PromosTab> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _applyCode() {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    final notifier = ref.read(promosProvider.notifier);
    if (!notifier.isValid(code)) {
      AppSnack.error(context, 'That code isn’t valid.');
      return;
    }
    final offer = notifier.apply(code);
    _code.clear();
    FocusScope.of(context).unfocus();
    AppSnack.success(context, '${offer.code} applied — ${offer.percentOff}% off.');
  }

  void _applyOffer(PromoOffer offer) {
    ref.read(promosProvider.notifier).apply(offer.code);
    AppSnack.success(context, '${offer.code} applied — ${offer.percentOff}% off.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promosProvider);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
      children: [
        _RewardsCard(points: state.points),
        const SizedBox(height: Spacing.x5),
        // Apply-code row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Enter promo code',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
                onSubmitted: (_) => _applyCode(),
              ),
            ),
            const SizedBox(width: Spacing.x3),
            SizedBox(
              height: Sizes.fieldHeight,
              child: FilledButton(
                onPressed: _applyCode,
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
        if (state.applied != null) ...[
          const SizedBox(height: Spacing.x4),
          _AppliedBanner(
            offer: state.applied!,
            onClear: () => ref.read(promosProvider.notifier).clear(),
          ),
        ],
        const SizedBox(height: Spacing.x6),
        Text('AVAILABLE OFFERS',
            style: text.labelSmall?.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: Spacing.x3),
        for (final offer in state.offers) ...[
          _OfferTile(offer: offer, onApply: () => _applyOffer(offer)),
          const SizedBox(height: Spacing.x3),
        ],
      ],
    );
  }
}

class _RewardsCard extends StatelessWidget {
  final int points;
  const _RewardsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final value = points / 100; // 100 pts = $1
    return Container(
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.accent,
        borderRadius: BorderRadius.circular(Radii.xxl),
        boxShadow: BrandShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined,
                  color: Colors.white, size: 20),
              const SizedBox(width: Spacing.x2),
              Text('Drivly rewards',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: Spacing.x4),
          Text('$points pts',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text('Worth ${Formatters.money(value)} off your next trip',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _AppliedBanner extends StatelessWidget {
  final PromoOffer offer;
  final VoidCallback onClear;
  const _AppliedBanner({required this.offer, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.successBg,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: BrandColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: BrandColors.success, size: 20),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Text(
              '${offer.code} applied — ${offer.percentOff}% off your next trip.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: BrandColors.foreground),
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Remove')),
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final PromoOffer offer;
  final VoidCallback onApply;
  const _OfferTile({required this.offer, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(
          color: offer.applied
              ? BrandColors.primary.withValues(alpha: 0.5)
              : BrandColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: Sizes.avatarMd,
            height: Sizes.avatarMd,
            decoration: BoxDecoration(
              color: BrandColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Text('${offer.percentOff}%',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: BrandColors.primary),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.title,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(offer.subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(offer.code,
                    style: BrandText.mono(
                        size: 12, color: BrandColors.mutedFg, spacing: 1)),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x2),
          offer.applied
              ? Icon(Icons.check_circle, color: BrandColors.primary)
              : OutlinedButton(
                  onPressed: onApply,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.x4),
                  ),
                  child: const Text('Apply'),
                ),
        ],
      ),
    );
  }
}

class _DashedAddTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DashedAddTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.x4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: BrandColors.primary, size: 20),
              const SizedBox(width: Spacing.x2),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: BrandColors.primary)),
            ],
          ),
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
      shape: CircleBorder(side: BorderSide(color: BrandColors.border)),
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
    final text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: Spacing.x4),
                decoration: BoxDecoration(
                  color: BrandColors.borderStrong,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
            Text('Top up wallet', style: text.titleLarge),
            const SizedBox(height: Spacing.x1),
            Text('Choose an amount to add to your balance.',
                style: text.bodySmall),
            const SizedBox(height: Spacing.x5),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: Spacing.x3,
              crossAxisSpacing: Spacing.x3,
              childAspectRatio: 2.4,
              children: [
                for (final a in amounts)
                  _AmountTile(
                    label: '\$${a.toStringAsFixed(0)}',
                    onTap: () => Navigator.pop(context, a),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable quick-amount tile for top-up — single line, never wraps.
class _AmountTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AmountTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface2,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.xl),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: BrandColors.border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BrandColors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
