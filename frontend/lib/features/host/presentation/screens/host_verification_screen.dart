import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/host_verification.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/host_service.dart';
import '../../domain/providers/host_provider.dart';

/// Host onboarding — spec §7.27.
///
/// 4-step progress: Identity · Vehicle · Insurance · Payout.
/// Each step has StatusBadge: done→success, pending/in-review→warning,
/// not-started→neutral. Progress bar in primary. 'Continue' PrimaryButton.
class HostVerificationScreen extends ConsumerStatefulWidget {
  const HostVerificationScreen({super.key});

  @override
  ConsumerState<HostVerificationScreen> createState() =>
      _HostVerificationScreenState();
}

class _HostVerificationScreenState
    extends ConsumerState<HostVerificationScreen> {
  bool _busy = false;

  // Map model keys to spec step labels: §7.27 Identity·Vehicle·Insurance·Payout
  static String _specLabel(String key) => switch (key) {
        'identity' => 'Identity',
        'vehicle' => 'Vehicle',
        'bank' => 'Payout',
        'agreement' => 'Insurance',
        _ => key,
      };

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
          Text(
            'Complete a quick 4-step verification to list your first car.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: BrandColors.mutedFg),
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

    // Spec-ordered steps: Identity · Vehicle · Insurance · Payout
    // Model order: identity, bank, vehicle, agreement
    // Reorder to match spec: identity, vehicle, agreement(insurance), bank(payout)
    final specOrdered = [
      v.steps.firstWhere((s) => s.key == 'identity',
          orElse: () => const HostVerificationStep('identity', 'Identity', 'pending')),
      v.steps.firstWhere((s) => s.key == 'vehicle',
          orElse: () => const HostVerificationStep('vehicle', 'Vehicle', 'pending')),
      v.steps.firstWhere((s) => s.key == 'agreement',
          orElse: () => const HostVerificationStep('agreement', 'Insurance', 'pending')),
      v.steps.firstWhere((s) => s.key == 'bank',
          orElse: () => const HostVerificationStep('bank', 'Payout', 'pending')),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x2, Spacing.x5, Spacing.x8),
      children: [
        // Completion header: % done + progress bar in primary
        _CompletionHeader(
          percent: percent,
          progress: total == 0 ? 0 : completed / total,
          stepsLeft: pending,
          isComplete: v.isComplete,
        ),
        const SizedBox(height: Spacing.x6),
        Text(
          'VERIFICATION STEPS',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: BrandColors.mutedFg),
        ),
        const SizedBox(height: Spacing.x3),
        // 4-step cards with StatusBadge per status
        for (final step in specOrdered) ...[
          _StepCard(
            step: step,
            specLabel: _specLabel(step.key),
            busy: _busy,
            onSubmit: () => _submitStep(step.key),
          ),
          const SizedBox(height: Spacing.x3),
        ],
        if (!v.isComplete) ...[
          const SizedBox(height: Spacing.x2),
          _PrimaryButton(
            label: 'Continue',
            loading: _busy,
            onPressed: () {
              // Submit first incomplete step
              final first = specOrdered.firstWhere(
                (s) => !s.isApproved,
                orElse: () => specOrdered.first,
              );
              _submitStep(first.key);
            },
          ),
        ],
        if (v.isComplete) ...[
          const SizedBox(height: Spacing.x2),
          Container(
            padding: const EdgeInsets.all(Spacing.x4),
            decoration: BoxDecoration(
              color: BrandColors.successBg,
              borderRadius: BorderRadius.circular(Radii.xl),
              border: Border.all(
                  color: BrandColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: BrandColors.success),
                const SizedBox(width: Spacing.x3),
                Expanded(
                  child: Text(
                    'Verification complete — you can list cars now!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: BrandColors.success,
                        ),
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

// ─── Completion header ────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(Radii.xl),
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
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: BrandColors.primary),
                    ),
                    const SizedBox(height: Spacing.x1),
                    Text(
                      'Verification complete',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: BrandColors.mutedFg),
                    ),
                  ],
                ),
              ),
              if (!isComplete)
                StatusBadge(
                  '$stepsLeft STEP${stepsLeft == 1 ? '' : 'S'} LEFT',
                  tone: BadgeTone.warning,
                ),
            ],
          ),
          const SizedBox(height: Spacing.x4),
          // Progress bar in primary
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

// ─── Step card with StatusBadge ───────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final HostVerificationStep step;
  final String specLabel;
  final bool busy;
  final VoidCallback onSubmit;

  const _StepCard({
    required this.step,
    required this.specLabel,
    required this.busy,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusText, statusIcon) = _statusVisuals();

    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(
          color: step.isApproved
              ? BrandColors.success.withValues(alpha: 0.35)
              : BrandColors.border,
        ),
      ),
      child: Row(
        children: [
          // Status circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: Spacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(specLabel,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  statusText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          // Spec: done→success, pending/in-review→warning, not-started→neutral
          _badge(),
        ],
      ),
    );
  }

  Widget _badge() {
    if (step.isApproved) {
      return const StatusBadge('Done',
          tone: BadgeTone.success, icon: Icons.check);
    }
    if (step.isSubmitted) {
      return const StatusBadge('In Review', tone: BadgeTone.warning);
    }
    if (step.isRejected) {
      return const StatusBadge('Rejected', tone: BadgeTone.error);
    }
    // not started
    return const StatusBadge('Not started', tone: BadgeTone.neutral);
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

// ─── Shared header ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x3),
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
            color: BrandColors.foreground, size: Sizes.iconLg),
      ),
    );
  }
}

/// Full-width lime pill primary button.
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
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: BrandColors.primaryFg),
            )
          : Text(label),
    );
  }
}
