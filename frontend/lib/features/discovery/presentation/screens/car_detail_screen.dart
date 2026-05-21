import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/car.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/car_service.dart';
import '../../data/favorite_service.dart';
import '../../domain/providers/car_provider.dart';

/// Car detail screen — spec §7.11.
///
/// Transparent AppBar over 320h photo carousel; sticky bottom bar with
/// [headlineMedium] price in primary. Favourite heart filled →
/// [BrandColors.destructive]. Scrim uses [BrandColors.overlay] alpha only —
/// zero hard-coded `Color(0x..)` literals.
class CarDetailScreen extends ConsumerStatefulWidget {
  final String carId;

  const CarDetailScreen({super.key, required this.carId});

  @override
  ConsumerState<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends ConsumerState<CarDetailScreen> {
  bool _favorite = false;
  bool _favBusy = false;
  int _photoIndex = 0;

  Future<void> _toggleFavorite() async {
    setState(() => _favBusy = true);
    try {
      final added =
          await ref.read(favoriteServiceProvider).toggle(widget.carId);
      setState(() => _favorite = added);
    } catch (_) {
      _snack('Could not update favourites.');
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(carDetailProvider(widget.carId));

    return Scaffold(
      body: AsyncValueView<CarDetailResult>(
        value: detail,
        onRetry: () => ref.invalidate(carDetailProvider(widget.carId)),
        data: (result) => _content(result.car),
      ),
      bottomNavigationBar: detail.maybeWhen(
        data: (result) => _bottomBar(result.car),
        orElse: () => null,
      ),
    );
  }

  Widget _content(Car car) {
    final text = Theme.of(context).textTheme;
    final photos = car.photos.isNotEmpty
        ? car.photos.map((p) => p.url).toList()
        : <String>[car.coverPhotoUrl ?? ''];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _gallery(car, photos)),
        SliverPadding(
          padding: const EdgeInsets.all(Spacing.x5),
          sliver: SliverList.list(
            children: [
              // Title row: 'Model · Year' displayMedium + fuel pill.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      car.displayNameWithYear,
                      style: text.displayMedium,
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  _CategoryPill(label: _humanise(car.fuelType)),
                ],
              ),
              const SizedBox(height: Spacing.x3),

              // Rating chip + host status.
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 18, color: BrandColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    car.averageRating.toStringAsFixed(2),
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '  ·  ${car.totalReviews} trips  ·  ',
                    style: text.bodySmall,
                  ),
                  Flexible(
                    child: Text(
                      'All-Star Host',
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                          color: BrandColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x5),

              // 4 spec tiles on surface2.
              _specChips(car),
              const SizedBox(height: Spacing.x6),

              // Host row: avatar 48 + 'Hosted by … · Superhost' + chevron.
              _hostCard(car),
              const SizedBox(height: Spacing.x6),

              // Feature chips.
              if (car.features.isNotEmpty) ...[
                const SectionHeader(title: 'Features'),
                const SizedBox(height: Spacing.x3),
                Wrap(
                  spacing: Spacing.x2,
                  runSpacing: Spacing.x2,
                  children: [
                    for (final f in car.features)
                      _FeaturePill(label: _humanise(f)),
                  ],
                ),
                const SizedBox(height: Spacing.x6),
              ],

              // Expandable description.
              if (car.description != null &&
                  car.description!.isNotEmpty) ...[
                const SectionHeader(title: 'About this car'),
                const SizedBox(height: Spacing.x2),
                Text(
                  car.description!,
                  style: text.bodyMedium
                      ?.copyWith(color: BrandColors.mutedFg, height: 1.5),
                ),
                const SizedBox(height: Spacing.x6),
              ],

              // Reviews preview.
              SectionHeader(
                title: 'Reviews',
                actionLabel: 'See all',
                onAction: () => context.push('/reviews/${car.id}'),
              ),
              const SizedBox(height: Spacing.x3),
              _reviewsPreview(car.id),
              const SizedBox(height: Spacing.x4),
            ],
          ),
        ),
      ],
    );
  }

  // ── Image gallery: 320h carousel + bottom↗top gradient scrim + overlaid
  //    share/favourite IconRoundButtons (44, surface2 fill + border) ──────────
  Widget _gallery(Car car, List<String> photos) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          Hero(
            tag: 'car-${car.id}',
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: PageView(
                onPageChanged: (i) => setState(() => _photoIndex = i),
                children: [
                  for (final url in photos)
                    AppNetworkImage(url: url, fit: BoxFit.cover),
                ],
              ),
            ),
          ),

          // Bottom→top gradient scrim using token colours (no literals).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      BrandColors.background.withValues(alpha: 0.80),
                      BrandColors.background.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top controls: back + share + favourite.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.x4, vertical: Spacing.x2),
                child: Row(
                  children: [
                    _circleIcon(Icons.arrow_back, () => context.pop()),
                    const Spacer(),
                    _circleIcon(Icons.share_outlined, () {
                      Share.share(
                        'Check out this ${car.displayNameWithYear} on Drivly',
                      );
                    }),
                    const SizedBox(width: Spacing.x2),
                    _circleIcon(
                      _favorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      _favBusy ? null : _toggleFavorite,
                      // filled heart → destructive; unfilled → white.
                      color: _favorite
                          ? BrandColors.destructive
                          : Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Page dots.
          if (photos.length > 1)
            Positioned(
              bottom: Spacing.x4,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _photoIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _photoIndex
                            ? BrandColors.primary
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius:
                            BorderRadius.circular(Radii.pill),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── 4 spec tiles on surface2 ─────────────────────────────────────────────
  Widget _specChips(Car car) {
    final items = <(IconData, String)>[
      (Icons.event_seat_outlined, '${car.seats} seats'),
      (Icons.door_front_door_outlined, '4 doors'),
      (Icons.settings_outlined, car.isAutomatic ? 'Automatic' : 'Manual'),
      (Icons.local_gas_station_outlined, _humanise(car.fuelType)),
    ];
    return Wrap(
      spacing: Spacing.x2,
      runSpacing: Spacing.x2,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.x3, vertical: 10),
            decoration: BoxDecoration(
              color: BrandColors.surface2,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: BrandColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 16, color: BrandColors.primary),
                const SizedBox(width: 6),
                Text(item.$2,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BrandColors.foreground)),
              ],
            ),
          ),
      ],
    );
  }

  // ── Host row: avatar 48 + 'Hosted by … · Superhost' + message chevron ──
  Widget _hostCard(Car car) {
    final host = car.host;
    final joined = car.createdAt?.year;
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface2,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          // Avatar 48.
          CircleAvatar(
            radius: Sizes.avatarMd / 2,
            backgroundColor: BrandColors.accent,
            child: Text(
              host?.initials ?? 'H',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hosted by ${host?.name ?? 'Host'}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Superhost badge.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: BrandColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Radii.pill),
                        border: Border.all(
                            color: BrandColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Superhost',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: BrandColors.primary,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.x1),
                Text(
                  '${joined != null ? 'Joined $joined · ' : ''}Responds in 5 min',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x2),
          // Chevron / message button.
          Material(
            color: BrandColors.surface3,
            shape: const CircleBorder(
                side: BorderSide(color: BrandColors.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/messages'),
              child: const SizedBox(
                width: Sizes.iconRoundButton,
                height: Sizes.iconRoundButton,
                child: Icon(Icons.chevron_right,
                    color: BrandColors.mutedFg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reviews preview ──────────────────────────────────────────────────────
  Widget _reviewsPreview(String carId) {
    final reviews = ref.watch(carReviewsProvider(carId));
    return reviews.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Spacing.x4),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (page) {
        if (page.items.isEmpty) {
          return Text(
            'No reviews yet. Be the first after your trip!',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: BrandColors.mutedFg),
          );
        }
        return Column(
          children: [
            for (final r in page.items.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.x3),
                child: Container(
                  padding: const EdgeInsets.all(Spacing.x4),
                  decoration: BoxDecoration(
                    color: BrandColors.surface2,
                    borderRadius: BorderRadius.circular(Radii.xl),
                    border: Border.all(color: BrandColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: BrandColors.accent,
                            child: Text(
                              r.reviewer?.initials ?? '?',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: Spacing.x2),
                          Text(
                            r.reviewer?.name ?? 'Renter',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          RatingStars(
                              rating: r.rating.toDouble(),
                              showValue: true),
                        ],
                      ),
                      if (r.comment != null &&
                          r.comment!.isNotEmpty) ...[
                        const SizedBox(height: Spacing.x2),
                        Text(
                          r.comment!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: BrandColors.mutedFg),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Sticky bottom bar: price headlineMedium primary + DateRange + Book ──
  Widget _bottomBar(Car car) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.surface,
        border: Border(top: BorderSide(color: BrandColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x4),
          child: Row(
            children: [
              // Price 'AED 220/day' headlineMedium primary.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: Formatters.money(car.dailyPrice),
                          style: text.headlineMedium
                              ?.copyWith(color: BrandColors.primary),
                        ),
                        TextSpan(
                          text: '/day',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.x1),
                  // DateRange pill.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.x3, vertical: 4),
                    decoration: BoxDecoration(
                      color: BrandColors.surface2,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(color: BrandColors.border),
                    ),
                    child: Text(
                      'Add dates',
                      style: text.bodySmall
                          ?.copyWith(color: BrandColors.mutedFg),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: Spacing.x4),
              // PrimaryButton 'Book'.
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/datetime', extra: car),
                  child: const Text('Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gallery circle icon button (surface2/border, 44dp) ───────────────────
  Widget _circleIcon(IconData icon, VoidCallback? onTap, {Color? color}) {
    return Material(
      // Scrim using token: overlay colour at 45% opacity.
      color: BrandColors.overlay.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: Sizes.iconRoundButton,
          height: Sizes.iconRoundButton,
          child: Icon(icon,
              color: color ?? Colors.white, size: Sizes.iconSm),
        ),
      ),
    );
  }

  static String _humanise(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ── Category pill ─────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Spacing.x3, vertical: 6),
      decoration: BoxDecoration(
        color: BrandColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(
            color: BrandColors.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: BrandColors.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

// ── Feature pill ──────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final String label;

  const _FeaturePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x3, vertical: 8),
      decoration: BoxDecoration(
        color: BrandColors.surface2,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 14, color: BrandColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: BrandColors.foreground)),
        ],
      ),
    );
  }
}
