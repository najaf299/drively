import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/host_verification.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/host_service.dart';
import '../../domain/providers/host_provider.dart';

/// Host onboarding wizard: identity → bank → vehicle → agreement.
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
      appBar: AppBar(title: const Text('Become a host')),
      body: AsyncValueView<HostVerification>(
        value: verification,
        onRetry: () => ref.invalidate(hostVerificationProvider),
        data: (v) {
          if (v.notStarted) return _notStarted();
          return _steps(v);
        },
      ),
    );
  }

  Widget _notStarted() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium_outlined,
              size: 64, color: BrandColors.primary),
          const SizedBox(height: Spacing.x4),
          Text('Start earning with your car',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: Spacing.x2),
          const Text(
            'Complete a quick 4-step verification to list your first car.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BrandColors.mutedFg),
          ),
          const SizedBox(height: Spacing.x6),
          LoadingButton(
            label: 'Start verification',
            loading: _busy,
            onPressed: _initiate,
          ),
        ],
      ),
    );
  }

  Widget _steps(HostVerification v) {
    final completed = v.completedSteps;
    return ListView(
      padding: const EdgeInsets.all(Spacing.x5),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: completed / 4,
            minHeight: 8,
            backgroundColor: BrandColors.surface2,
          ),
        ),
        const SizedBox(height: Spacing.x2),
        Text('$completed of 4 steps complete',
            style: const TextStyle(color: BrandColors.mutedFg)),
        const SizedBox(height: Spacing.x5),
        for (final step in v.steps) ...[
          _stepCard(step),
          const SizedBox(height: Spacing.x3),
        ],
        if (v.isComplete)
          const Padding(
            padding: EdgeInsets.only(top: Spacing.x4),
            child: Center(
              child: Text('Verification complete — you can list cars now!',
                  style: TextStyle(color: BrandColors.success)),
            ),
          ),
      ],
    );
  }

  Widget _stepCard(HostVerificationStep step) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                StatusChip.verification(step.status),
              ],
            ),
          ),
          if (!step.isApproved && !step.isSubmitted)
            FilledButton(
              onPressed: _busy ? null : () => _submitStep(step.key),
              child: const Text('Submit'),
            )
          else if (step.isApproved)
            const Icon(Icons.check_circle, color: BrandColors.success),
        ],
      ),
    );
  }
}
