import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/review.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../discovery/domain/providers/car_provider.dart';

/// All reviews for a car.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, 0, Spacing.x5, Spacing.x5),
            children: [
              _summary(context, avg, cleanliness, communication, accuracy),
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
              decoration: const BoxDecoration(
                color: BrandColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  size: 20, color: BrandColors.foreground),
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Text(
            'Reviews · $total',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: BrandColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    double avg,
    double? cleanliness,
    double? communication,
    double? accuracy,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card + 4),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                avg.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: BrandColors.primary,
                ),
              ),
              const SizedBox(width: Spacing.x3),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < avg.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 20,
                      color: BrandColors.primary,
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.x4),
          _bar('Cleanliness', cleanliness != null ? cleanliness / 5 : 0.98),
          const SizedBox(height: Spacing.x3),
          _bar('Communication',
              communication != null ? communication / 5 : 0.96),
          const SizedBox(height: Spacing.x3),
          _bar('Accuracy', accuracy != null ? accuracy / 5 : 0.99),
        ],
      ),
    );
  }

  Widget _bar(String label, double value) {
    final pct = (value.clamp(0, 1) * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
                color: BrandColors.mutedFg, fontSize: 13),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: BrandColors.surface2,
              valueColor:
                  const AlwaysStoppedAnimation(BrandColors.primary),
            ),
          ),
        ),
        const SizedBox(width: Spacing.x3),
        SizedBox(
          width: 38,
          child: Text(
            '$pct%',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: BrandColors.foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
              _CoralAvatar(initials: review.reviewer?.initials ?? '?'),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer?.name ?? 'Renter',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: BrandColors.foreground,
                      ),
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
                            color: BrandColors.primary,
                          );
                        }),
                        if (review.createdAt != null) ...[
                          const SizedBox(width: Spacing.x2),
                          Text(
                            Formatters.timeAgo(review.createdAt!),
                            style: const TextStyle(
                                color: BrandColors.mutedFg, fontSize: 12),
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
              style: const TextStyle(
                  color: BrandColors.foreground, height: 1.45),
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
                          borderRadius:
                              BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                              fontSize: 11, color: BrandColors.mutedFg),
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

class _CoralAvatar extends StatelessWidget {
  final String initials;
  const _CoralAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: BrandColors.accent,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: BrandColors.primaryFg,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
