import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/car.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_avatar.dart';
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
        SliverAppBar(
          pinned: true,
          expandedHeight: 280,
          backgroundColor: BrandColors.background,
          leading: _circleIcon(Icons.arrow_back, () => context.pop()),
          actions: [
            _circleIcon(Icons.share_outlined, () {
              Share.share(
                'Check out this ${car.displayNameWithYear} on Drivly',
              );
            }),
            _circleIcon(
              _favorite ? Icons.favorite : Icons.favorite_border,
              _favBusy ? null : _toggleFavorite,
              color: _favorite ? BrandColors.destructive : Colors.white,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'car-${car.id}',
              child: PageView(
                children: [
                  for (final url in photos)
                    AppNetworkImage(url: url, fit: BoxFit.cover),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(Spacing.x5),
          sliver: SliverList.list(children: [
            Text(car.displayNameWithYear, style: text.headlineMedium),
            const SizedBox(height: Spacing.x2),
            Row(
              children: [
                RatingStars(
                  rating: car.averageRating,
                  showValue: true,
                  reviewCount: car.totalReviews,
                ),
                const SizedBox(width: Spacing.x3),
                const Icon(Icons.location_on_outlined,
                    size: 15, color: BrandColors.mutedFg),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(car.city,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: BrandColors.mutedFg)),
                ),
              ],
            ),
            const SizedBox(height: Spacing.x5),
            _specsRow(car),
            const SizedBox(height: Spacing.x6),
            _hostCard(car),
            const SizedBox(height: Spacing.x6),
            if (car.features.isNotEmpty) ...[
              Text('Features', style: text.titleMedium),
              const SizedBox(height: Spacing.x3),
              Wrap(
                spacing: Spacing.x2,
                runSpacing: Spacing.x2,
                children: [
                  for (final f in car.features)
                    Chip(
                      label: Text(_humanise(f)),
                      avatar: const Icon(Icons.check, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.x6),
            ],
            if (car.description != null && car.description!.isNotEmpty) ...[
              Text('About this car', style: text.titleMedium),
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

  Widget _specsRow(Car car) {
    final items = [
      (Icons.event_seat_outlined, '${car.seats}', 'Seats'),
      (Icons.sensor_door_outlined, '${car.doors}', 'Doors'),
      (Icons.settings_outlined, car.isAutomatic ? 'Auto' : 'Manual', 'Gearbox'),
      (Icons.local_gas_station_outlined, _humanise(car.fuelType), 'Fuel'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          for (final i in items)
            Expanded(
              child: Column(
                children: [
                  Icon(i.$1, color: BrandColors.primary),
                  const SizedBox(height: Spacing.x1),
                  Text(i.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(i.$3,
                      style: const TextStyle(
                          color: BrandColors.mutedFg, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _hostCard(Car car) {
    final host = car.host;
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: host?.avatarUrl,
            initials: host?.initials ?? 'H',
            radius: 24,
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(host?.name ?? 'Host',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  host?.totalTrips != null
                      ? '${host!.totalTrips} trips hosted'
                      : 'Verified host',
                  style:
                      const TextStyle(color: BrandColors.mutedFg, fontSize: 12),
                ),
              ],
            ),
          ),
          if (host?.averageRating != null)
            RatingStars(rating: host!.averageRating!, showValue: true),
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
                  padding: const EdgeInsets.all(Spacing.x3),
                  decoration: BoxDecoration(
                    color: BrandColors.surface,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: BrandColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            imageUrl: r.reviewer?.avatarUrl,
                            initials: r.reviewer?.initials ?? '?',
                            radius: 14,
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

  Widget _bottomBar(Car car) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(Spacing.x4),
        decoration: const BoxDecoration(
          color: BrandColors.surface,
          border: Border(top: BorderSide(color: BrandColors.border)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Formatters.money(car.dailyPrice),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: BrandColors.primary,
                        fontWeight: FontWeight.w700)),
                const Text('per day',
                    style: TextStyle(color: BrandColors.mutedFg, fontSize: 12)),
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
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback? onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: color ?? Colors.white, size: 20),
          onPressed: onTap,
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
