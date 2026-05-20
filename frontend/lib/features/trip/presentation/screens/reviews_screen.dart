import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/review.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../discovery/domain/providers/car_provider.dart';

/// All reviews for a car.
class ReviewsScreen extends ConsumerWidget {
  final String carId;
  const ReviewsScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(carReviewsProvider(carId));
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: AsyncValueView<Paginated<Review>>(
        value: reviews,
        onRetry: () => ref.invalidate(carReviewsProvider(carId)),
        data: (page) {
          if (page.items.isEmpty) {
            return const EmptyView(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              subtitle: 'Reviews appear here after completed trips.',
            );
          }
          final avg = page.items.fold<double>(0, (s, r) => s + r.rating) /
              page.items.length;
          return ListView(
            padding: const EdgeInsets.all(Spacing.x5),
            children: [
              Row(
                children: [
                  Text(avg.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(width: Spacing.x3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingStars(rating: avg, size: 20),
                      Text('${page.total} reviews',
                          style: const TextStyle(color: BrandColors.mutedFg)),
                    ],
                  ),
                ],
              ),
              const Divider(color: BrandColors.border, height: Spacing.x8),
              for (final r in page.items) ...[
                _ReviewTile(review: r),
                const SizedBox(height: Spacing.x4),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppAvatar(
              imageUrl: review.reviewer?.avatarUrl,
              initials: review.reviewer?.initials ?? '?',
              radius: 18,
            ),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.reviewer?.name ?? 'Renter',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (review.createdAt != null)
                    Text(Formatters.timeAgo(review.createdAt!),
                        style: const TextStyle(
                            color: BrandColors.mutedFg, fontSize: 12)),
                ],
              ),
            ),
            RatingStars(rating: review.rating.toDouble(), showValue: true),
          ],
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: Spacing.x2),
          Text(review.comment!,
              style: const TextStyle(color: BrandColors.mutedFg, height: 1.4)),
        ],
        if (review.tags.isNotEmpty) ...[
          const SizedBox(height: Spacing.x2),
          Wrap(
            spacing: Spacing.x2,
            children: review.tags
                .map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
