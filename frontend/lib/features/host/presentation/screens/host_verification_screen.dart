import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/host_verification.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/host_service.dart';
import '../../domain/providers/host_provider.dart';

/// Host onboarding wizard: identity → bank → vehicle → agreement.
///
/// Restyled to the Drivly "Become a host" design: a completion header with a
/// large lime percentage, a steps-left chip and a lime progress bar, followed
/// by a checklist of status cards.
class HostVerificationScreen extends ConsumerStatefulWidget {
  const HostVerificationScreen({super.key});

  @override
  ConsumerState<HostVerificationScreen> createState() =>
      _HostVerificationScreenState();
}

class _HostVerificationScreenState
    extends ConsumerState<HostVerificationScreen> {
  bool _busy = false;

  Future<void> _initiate() async {
    setState(() => _busy = true);
    try {
      await ref.read(hostServiceProvider).initiateVerification();
      ref.invalidate(hostVerificationProvider);
    } catch (_) {
      _snack('Could not start verification.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitStep(String step) async {
    setState(() => _busy = true);
    try {
      // Document upload to object storage happens out-of-band; here we mark the
      // step as submitted for review.
      await ref.read(hostServiceProvider).updateStep(step, {'submitted': true});
      ref.invalidate(hostVerificationProvider);
      await ref.read(authProvider.notifier).refreshUser();
    } catch (_) {
      _snack('Could not submit this step.');
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
    final verification = ref.watch(hostVerificationProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: 'Become a host',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/host'),
            ),
            Expanded(
              child: AsyncValueView<HostVerification>(
                value: verification,
                onRetry: () => ref.invalidate(hostVerificationProvider),
                data: (v) {
                  if (v.notStarted) return _notStarted();
                  return _steps(v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notStarted() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: BrandColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                size: 44, color: BrandColors.primary),
          ),
          const SizedBox(height: Spacing.x5),
          Text('Start earning with your car',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: Spacing.x3),
          const Text(
            'Complete a quick 4-step verification to list your first car.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BrandColors.mutedFg, height: 1.4),
          ),
          const SizedBox(height: Spacing.x8),
          _PrimaryButton(
            label: 'Start verification',
            loading: _busy,
            onPressed: _initiate,
          ),
        ],
      ),
    );
  }

  Widget _steps(HostVerification v) {
    final total = v.steps.length;
    final completed = v.completedSteps;
    final pending = total - completed;
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(Spacing.x5, Spacing.x2, Spacing.x5,
          Spacing.x8),
      children: [
        _CompletionHeader(
          percent: percent,
          progress: total == 0 ? 0 : completed / total,
          stepsLeft: pending,
          isComplete: v.isComplete,
        ),
        const SizedBox(height: Spacing.x6),
        const Text(
          'VERIFICATION STEPS',
          style: TextStyle(
            color: BrandColors.mutedFg,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: Spacing.x3),
        for (final step in v.steps) ...[
          _StepCard(
            step: step,
            busy: _busy,
            onSubmit: () => _submitStep(step.key),
          ),
          const SizedBox(height: Spacing.x3),
        ],
        if (v.isComplete) ...[
          const SizedBox(height: Spacing.x2),
          Container(
            padding: const EdgeInsets.all(Spacing.x4),
            decoration: BoxDecoration(
              color: BrandColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.card),
              border:
                  Border.all(color: BrandColors.success.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: BrandColors.success),
                SizedBox(width: Spacing.x3),
                Expanded(
                  child: Text(
                    'Verification complete — you can list cars now!',
                    style: TextStyle(
                        color: BrandColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Big lime percent + "Verification complete" + steps-left chip + lime bar.
class _CompletionHeader extends StatelessWidget {
  final int percent;
  final double progress;
  final int stepsLeft;
  final bool isComplete;

  const _CompletionHeader({
    required this.percent,
    required this.progress,
    required this.stepsLeft,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: BrandColors.primary,
                        fontSize: 44,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: Spacing.x1),
                    const Text(
                      'Verification complete',
                      style: TextStyle(color: BrandColors.mutedFg),
                    ),
                  ],
                ),
              ),
              if (!isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BrandColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(
                        color: BrandColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '$stepsLeft STEP${stepsLeft == 1 ? '' : 'S'} LEFT',
                    style: const TextStyle(
                      color: BrandColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.x4),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: BrandColors.surface2,
              color: BrandColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A checklist step card: leading status circle + label + status/action.
class _StepCard extends StatelessWidget {
  final HostVerificationStep step;
  final bool busy;
  final VoidCallback onSubmit;

  const _StepCard({
    required this.step,
    required this.busy,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel, statusIcon) = _statusVisuals();

    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: step.isApproved
              ? BrandColors.success.withValues(alpha: 0.35)
              : BrandColors.border,
        ),
      ),
      child: Row(
        children: [
          // Leading status circle.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: Spacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ],
            ),
          ),
          _trailing(),
        ],
      ),
    );
  }

  Widget _trailing() {
    if (step.isApproved) {
      return const Icon(Icons.check_circle, color: BrandColors.success);
    }
    if (step.isRejected) {
      return TextButton(
        onPressed: busy ? null : onSubmit,
        style: TextButton.styleFrom(foregroundColor: BrandColors.destructive),
        child: const Text('Retry'),
      );
    }
    if (step.isSubmitted) {
      // Pending review → amber "REVIEW" pill.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: BrandColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: const Text(
          'REVIEW',
          style: TextStyle(
            color: BrandColors.warning,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    // Pending → "Start →" lime action.
    return TextButton(
      onPressed: busy ? null : onSubmit,
      style: TextButton.styleFrom(foregroundColor: BrandColors.primary),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Start', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 16),
        ],
      ),
    );
  }

  (Color, String, IconData) _statusVisuals() {
    if (step.isApproved) {
      return (BrandColors.success, 'Verified', Icons.check);
    }
    if (step.isRejected) {
      return (BrandColors.destructive, 'Rejected', Icons.close);
    }
    if (step.isSubmitted) {
      return (BrandColors.warning, 'Pending review', Icons.more_horiz);
    }
    return (BrandColors.mutedFg, 'Not started', Icons.more_horiz);
  }
}

/// Shared circular-back header used across host wizard-style screens.
class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.x5, Spacing.x3, Spacing.x5,
          Spacing.x3),
      child: Row(
        children: [
          _CircleBackButton(onTap: onBack),
          const SizedBox(width: Spacing.x4),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.border),
        ),
        child: const Icon(Icons.chevron_left,
            color: BrandColors.foreground, size: 26),
      ),
    );
  }
}

/// Full-width lime pill primary button (~56 tall, radius 28).
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.primaryFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BrandColors.primaryFg),
              )
            : Text(label),
      ),
    );
  }
}
