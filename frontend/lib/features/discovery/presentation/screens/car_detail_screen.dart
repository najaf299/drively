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
          sliver: SliverList.list(children: [
            // Title + category pill.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(car.displayNameWithYear,
                      style: text.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: Spacing.x3),
                _CategoryPill(label: _humanise(car.fuelType)),
              ],
            ),
            const SizedBox(height: Spacing.x3),
            // Rating line.
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 18, color: BrandColors.warning),
                const SizedBox(width: 4),
                Text(
                  car.averageRating.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '  ·  ${car.totalReviews} trips  ·  ',
                  style: const TextStyle(color: BrandColors.mutedFg),
                ),
                const Flexible(
                  child: Text(
                    'All-Star Host',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BrandColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.x5),
            _specChips(car),
            const SizedBox(height: Spacing.x6),
            _hostCard(car),
            const SizedBox(height: Spacing.x6),
            if (car.features.isNotEmpty) ...[
              Text('Features', style: text.titleLarge),
              const SizedBox(height: Spacing.x3),
              Wrap(
                spacing: Spacing.x2,
                runSpacing: Spacing.x2,
                children: [
                  for (final f in car.features) _FeaturePill(label: _humanise(f)),
                ],
              ),
              const SizedBox(height: Spacing.x6),
            ],
            if (car.description != null && car.description!.isNotEmpty) ...[
              Text('About this car', style: text.titleLarge),
              const SizedBox(height: Spacing.x2),
              Text(car.description!,
                  style:
                      const TextStyle(color: BrandColors.mutedFg, height: 1.5)),
              const SizedBox(height: Spacing.x6),
            ],
            SectionHeader(
              title: 'Reviews',
              actionLabel: 'See all',
              onAction: () => context.push('/reviews/${car.id}'),
            ),
            const SizedBox(height: Spacing.x3),
            _reviewsPreview(car.id),
            const SizedBox(height: Spacing.x4),
          ]),
        ),
      ],
    );
  }

  // ── Image gallery with a bottom scrim + overlaid controls + page dots ──────
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
          // Bottom gradient scrim so overlaid controls/dots stay legible.
          const Positioned(
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
                    colors: [Color(0xCC0B0D14), Color(0x000B0D14)],
                  ),
                ),
              ),
            ),
          ),
          // Top controls.
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
                      _favorite ? Icons.favorite : Icons.favorite_border,
                      _favBusy ? null : _toggleFavorite,
                      color: _favorite ? BrandColors.accent : Colors.white,
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
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _photoIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _photoIndex
                            ? BrandColors.primary
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Spec chips with icons ──────────────────────────────────────────────────
  Widget _specChips(Car car) {
    final items = <(IconData, String)>[
      (Icons.event_seat_outlined, '${car.seats} seats'),
      (Icons.settings_outlined, car.isAutomatic ? 'Automatic' : 'Manual'),
      (Icons.local_gas_station_outlined, _humanise(car.fuelType)),
      (Icons.verified_user_outlined, 'Insured'),
    ];
    return Wrap(
      spacing: Spacing.x2,
      runSpacing: Spacing.x2,
      children: [
        for (final i in items)
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
                Icon(i.$1, size: 16, color: BrandColors.primary),
                const SizedBox(width: 6),
                Text(i.$2,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }

  // ── Host card ──────────────────────────────────────────────────────────────
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
          CircleAvatar(
            radius: 26,
            backgroundColor: BrandColors.accent,
            child: Text(
              host?.initials ?? 'H',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hosted by ${host?.name ?? 'Host'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${joined != null ? 'Joined $joined · ' : ''}Responds in 5 min',
                  style: const TextStyle(
                      color: BrandColors.mutedFg, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x2),
          Material(
            color: BrandColors.surface3,
            shape: const CircleBorder(
                side: BorderSide(color: BrandColors.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/messages'),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.chat_bubble_outline,
                    color: BrandColors.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          return const Text('No reviews yet. Be the first after your trip!',
              style: TextStyle(color: BrandColors.mutedFg));
        }
        return Column(
          children: [
            for (final r in page.items.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.x3),
                child: Container(
                  padding: const EdgeInsets.all(Spacing.x4),
                  decoration: BoxDecoration(
                    color: BrandColors.surface,
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.x2),
                          Text(r.reviewer?.name ?? 'Renter',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          RatingStars(
                              rating: r.rating.toDouble(), showValue: true),
                        ],
                      ),
                      if (r.comment != null && r.comment!.isNotEmpty) ...[
                        const SizedBox(height: Spacing.x2),
                        Text(r.comment!,
                            style: const TextStyle(color: BrandColors.mutedFg)),
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

  // ── Sticky bottom bar ──────────────────────────────────────────────────────
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
          padding: const EdgeInsets.all(Spacing.x4),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: Formatters.money(car.dailyPrice),
                          style: text.headlineMedium?.copyWith(
                            color: BrandColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: '/day',
                          style: TextStyle(
                              color: BrandColors.mutedFg, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Free cancellation',
                      style:
                          TextStyle(color: BrandColors.success, fontSize: 12)),
                ],
              ),
              const SizedBox(width: Spacing.x4),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/datetime', extra: car),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback? onTap, {Color? color}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color ?? Colors.white, size: 20),
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

/// Lime category pill used in the detail title row.
class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BrandColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: BrandColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Surface feature chip with a lime check.
class _FeaturePill extends StatelessWidget {
  final String label;
  const _FeaturePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Spacing.x3, vertical: 8),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 14, color: BrandColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
