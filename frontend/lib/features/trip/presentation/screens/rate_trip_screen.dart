import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../booking/domain/providers/booking_provider.dart';
import '../../data/review_service.dart';

/// Post-trip rating and review for a booking.
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

  static const _tagOptions = [
    'Friendly host',
    'Clean car',
    'Great value',
    'Easy pickup',
    'On time',
    'Spacious',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your trip')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.x5),
        children: [
          Center(
            child: Text('How was your trip?',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          const SizedBox(height: Spacing.x4),
          StarRatingInput(
            value: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: Spacing.x6),
          _categoryRow('Cleanliness', _cleanliness,
              (v) => setState(() => _cleanliness = v)),
          _categoryRow('Communication', _communication,
              (v) => setState(() => _communication = v)),
          _categoryRow(
              'Accuracy', _accuracy, (v) => setState(() => _accuracy = v)),
          _categoryRow('Pickup', _pickup, (v) => setState(() => _pickup = v)),
          const SizedBox(height: Spacing.x5),
          Text('What stood out?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.x2),
          Wrap(
            spacing: Spacing.x2,
            children: _tagOptions.map((t) {
              final sel = _tags.contains(t);
              return FilterChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) =>
                    setState(() => sel ? _tags.remove(t) : _tags.add(t)),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.x5),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Share details (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: Spacing.x4),
          LoadingButton(
            label: 'Submit review',
            loading: _busy,
            onPressed: _rating == 0 ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x1),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Row(
            children: List.generate(5, (i) {
              final filled = i < value;
              return GestureDetector(
                onTap: () => onChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 24,
                    color: filled ? BrandColors.warning : BrandColors.mutedFg,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
