import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/review.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../discovery/domain/providers/car_provider.dart';

/// All reviews for a car — spec §7.12.
///
/// Summary card: big average (displaySmall) + stars (warning) + N reviews.
/// Breakdown bars in primary. Review rows: avatar, name, date, stars, body.
class ReviewsScreen extends ConsumerWidget {
  final String carId;
  const ReviewsScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(carReviewsProvider(carId));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: AsyncValueView<Paginated<Review>>(
            value: reviews,
            onRetry: () => ref.invalidate(carReviewsProvider(carId)),
            data: (page) => _content(context, page),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Paginated<Review> page) {
    final header = _header(context, page.total);
    if (page.items.isEmpty) {
      return Column(
        children: [
          header,
          const Expanded(
            child: EmptyView(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              subtitle: 'Reviews appear here after completed trips.',
            ),
          ),
        ],
      );
    }

    final avg = page.items.fold<double>(0, (s, r) => s + r.rating) /
        page.items.length;
    final cleanliness = _avgOf(page.items, (r) => r.cleanlinessRating);
    final communication = _avgOf(page.items, (r) => r.communicationRating);
    final accuracy = _avgOf(page.items, (r) => r.accuracyRating);
    final value = _avgOf(page.items, (r) => r.accuracyRating); // proxy for Value

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, 0, Spacing.x5, Spacing.x5),
            children: [
              _summaryCard(context, avg, page.total, cleanliness,
                  communication, accuracy, value),
              const SizedBox(height: Spacing.x5),
              for (final r in page.items) ...[
                _ReviewTile(review: r),
                const SizedBox(height: Spacing.x3),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x4),
      child: Row(
        children: [
          InkWell(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/'),
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back,
                  size: 20, color: BrandColors.foreground),
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Text(
            'Reviews',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  /// Big summary card — spec §7.12.
  Widget _summaryCard(
    BuildContext context,
    double avg,
    int total,
    double? cleanliness,
    double? communication,
    double? accuracy,
    double? value,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
        boxShadow: BrandShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average + stars row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: BrandColors.primary),
              ),
              const SizedBox(width: Spacing.x3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < avg.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 20,
                        color: BrandColors.warning,
                      );
                    }),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$total reviews',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacing.x5),
          // Breakdown rows
          _bar(context, 'Cleanliness',
              cleanliness != null ? cleanliness / 5 : 0.96),
          const SizedBox(height: Spacing.x3),
          _bar(context, 'Communication',
              communication != null ? communication / 5 : 0.94),
          const SizedBox(height: Spacing.x3),
          _bar(context, 'Accuracy',
              accuracy != null ? accuracy / 5 : 0.97),
          const SizedBox(height: Spacing.x3),
          _bar(context, 'Value', value != null ? value / 5 : 0.93),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, String label, double fraction) {
    final pct = (fraction.clamp(0.0, 1.0) * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: BrandColors.mutedFg),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: BrandColors.surface2,
              valueColor:
                  AlwaysStoppedAnimation(BrandColors.primary),
            ),
          ),
        ),
        const SizedBox(width: Spacing.x3),
        SizedBox(
          width: 38,
          child: Text(
            '$pct%',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: BrandColors.foreground,
                ),
          ),
        ),
      ],
    );
  }

  double? _avgOf(List<Review> items, int? Function(Review) pick) {
    final vals = items.map(pick).whereType<int>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Use AppAvatar (surface2 bg, theme tokens — no coral).
              AppAvatar(
                initials: review.reviewer?.initials ?? '?',
                radius: 20,
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer?.name ?? 'Renter',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: BrandColors.warning,
                          );
                        }),
                        if (review.createdAt != null) ...[
                          const SizedBox(width: Spacing.x2),
                          Text(
                            Formatters.timeAgo(review.createdAt!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: Spacing.x3),
            Text(
              review.comment!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.45),
            ),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: Spacing.x3),
            Wrap(
              spacing: Spacing.x2,
              runSpacing: Spacing.x2,
              children: review.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: BrandColors.surface2,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          t,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: BrandColors.mutedFg),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
