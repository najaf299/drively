import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../booking/domain/providers/booking_provider.dart';
import '../../data/review_service.dart';

/// Post-trip rating screen — spec §6 rate trip.
///
/// Tappable 40-dp star row (fills primary) · tag chips (theme chips) ·
/// textarea (max 500) · submit PrimaryButton.
class RateTripScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const RateTripScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends ConsumerState<RateTripScreen> {
  int _rating = 0;
  int _cleanliness = 0;
  int _communication = 0;
  int _accuracy = 0;
  int _pickup = 0;
  final _comment = TextEditingController();
  final _tags = <String>{};
  bool _busy = false;

  /// Spec §7 tag chips: Clean · On time · Smooth ride · Great communication ·
  /// Car as described (plus legacy options mapped across).
  static const _tagOptions = [
    'Clean',
    'On time',
    'Smooth ride',
    'Great communication',
    'Car as described',
    'Easy pickup',
  ];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(reviewServiceProvider).submit(
            widget.bookingId,
            rating: _rating,
            cleanliness: _cleanliness == 0 ? null : _cleanliness,
            communication: _communication == 0 ? null : _communication,
            accuracy: _accuracy == 0 ? null : _accuracy,
            pickup: _pickup == 0 ? null : _pickup,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
            tags: _tags.isEmpty ? null : _tags.toList(),
          );
      ref.invalidate(bookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanks for your review!')));
        context.go('/trips');
      }
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x2),
                child: Row(
                  children: [
                    _circleBack(context),
                    const SizedBox(width: Spacing.x3),
                    Text('Rate your trip', style: t.headlineMedium),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x5),
                  children: [
                    // Prompt
                    Center(
                      child: Text(
                        'How was your trip?',
                        style: t.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: Spacing.x5),

                    // Main star row — 40 dp, fills primary.
                    StarRatingInput(
                      value: _rating,
                      onChanged: (v) => setState(() => _rating = v),
                      size: 40,
                      fillColor: BrandColors.primary,
                    ),
                    const SizedBox(height: Spacing.x6),

                    // Sub-category star rows
                    _categoryCard(context),
                    const SizedBox(height: Spacing.x5),

                    // Tag chips — use theme FilterChip.
                    Text('What stood out?', style: t.titleMedium),
                    const SizedBox(height: Spacing.x3),
                    Wrap(
                      spacing: Spacing.x2,
                      runSpacing: Spacing.x2,
                      children: _tagOptions.map((tag) {
                        final sel = _tags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: sel,
                          onSelected: (v) => setState(
                              () => v ? _tags.add(tag) : _tags.remove(tag)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: Spacing.x5),

                    // Textarea — max 500 chars.
                    TextField(
                      controller: _comment,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Tell others about your experience (max 500)',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),

              // Sticky submit CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, 0, Spacing.x5, Spacing.x4),
                child: FilledButton(
                  onPressed: _rating == 0 || _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BrandColors.primaryFg))
                      : const Text('Submit review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4, vertical: Spacing.x2),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        children: [
          _categoryRow(context, 'Cleanliness', _cleanliness,
              (v) => setState(() => _cleanliness = v)),
          _categoryRow(context, 'Communication', _communication,
              (v) => setState(() => _communication = v)),
          _categoryRow(context, 'Accuracy', _accuracy,
              (v) => setState(() => _accuracy = v)),
          _categoryRow(context, 'Pickup', _pickup,
              (v) => setState(() => _pickup = v)),
        ],
      ),
    );
  }

  Widget _categoryRow(
    BuildContext context,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Row(
            children: List.generate(5, (i) {
              final filled = i < value;
              return GestureDetector(
                onTap: () => onChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    filled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 26,
                    color: filled ? BrandColors.primary : BrandColors.mutedFg,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _circleBack(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.canPop() ? context.pop() : context.go('/trips'),
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
    );
  }
}
