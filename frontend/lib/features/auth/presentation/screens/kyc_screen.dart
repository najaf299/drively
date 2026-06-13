import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/kyc_service.dart';

/// Live KYC status for the current user.
final kycStatusProvider = FutureProvider.autoDispose<KycStatus>((ref) {
  return ref.watch(kycServiceProvider).status();
});

/// Driver's licence capture + KYC status (Step 3 of 3).
///
/// Image upload to object storage (Cloudflare R2) is performed by a dedicated
/// media service that is not part of this build; capture is wired here and the
/// resulting URLs are submitted via `KycService.submit`.
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _picker = ImagePicker();
  XFile? _front;
  XFile? _back;
  XFile? _selfie;
  bool _busy = false;

  Future<void> _capture(
      void Function(XFile) assign, ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) setState(() => assign(file));
    } catch (_) {
      _snack('Could not access the camera/gallery.');
    }
  }

  /// Opens the capture sheet for a given document slot.
  void _pick(void Function(XFile) assign) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _capture(assign, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _capture(assign, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_front == null) {
      _snack('Capture the front of your licence first.');
      return;
    }
    setState(() => _busy = true);
    try {
      // Upload each captured document to the public disk, then submit the URLs.
      final uploader = ref.read(uploadServiceProvider);
      final frontUrl = await uploader.uploadImage(_front!, folder: 'kyc');
      final backUrl = _back != null
          ? await uploader.uploadImage(_back!, folder: 'kyc')
          : null;
      final selfieUrl = _selfie != null
          ? await uploader.uploadImage(_selfie!, folder: 'kyc')
          : null;

      await ref.read(kycServiceProvider).submit(
            documentType: 'drivers_license',
            frontUrl: frontUrl,
            backUrl: backUrl,
            selfieUrl: selfieUrl,
          );

      ref.invalidate(kycStatusProvider);
      if (mounted) _snack('Documents submitted for review.');
    } on AppException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not submit documents. Please try again.');
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
    final status = ref.watch(kycStatusProvider);
    return Scaffold(
      body: SafeArea(
        child: AsyncValueView<KycStatus>(
          value: status,
          onRetry: () => ref.invalidate(kycStatusProvider),
          data: (kyc) => SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StepHeader(label: 'Step 3 of 3'),
                const SizedBox(height: Spacing.x4),
                // Top warning banner — warningBg/warning (spec §7.6).
                const _WarningBanner(
                  message: 'Verification required to book a car',
                ),
                const SizedBox(height: Spacing.x6),
                Text(
                  'Verify license',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: Spacing.x6),
                // 3:2 capture frame with L-shaped corner brackets.
                _CaptureFrame(
                  file: _front,
                  onTap: () => _pick((f) => _front = f),
                ),
                const SizedBox(height: Spacing.x6),
                // Checklist of required documents.
                _ChecklistCard(
                  items: [
                    _ChecklistItem(
                      title: 'Front of license',
                      subtitle: _front != null ? 'Captured' : 'Tap to capture',
                      done: _front != null,
                      onTap: () => _pick((f) => _front = f),
                    ),
                    _ChecklistItem(
                      title: 'Back of license',
                      subtitle: _back != null ? 'Captured' : 'Tap to capture',
                      done: _back != null,
                      onTap: () => _pick((f) => _back = f),
                    ),
                    _ChecklistItem(
                      title: 'Selfie verification',
                      subtitle: _selfie != null ? 'Captured' : 'Tap to start',
                      done: _selfie != null,
                      onTap: () => _pick((f) => _selfie = f),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.x5),
                // Encryption assurance.
                const _InfoCard(
                  text: 'Your documents are encrypted end-to-end and reviewed '
                      'within 5 minutes by our AI + human team.',
                ),
                const SizedBox(height: Spacing.x8),
                _PrimaryButton(
                  label: 'Continue verification',
                  busy: _busy,
                  onPressed: kyc.isApproved ? null : _submit,
                ),
                if (kyc.isApproved)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.x4),
                    child: Center(
                      child: Text(
                        'Your licence is verified',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: BrandColors.success),
                      ),
                    ),
                  ),
                const SizedBox(height: Spacing.x4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top warning banner — warningBg fill, warning text/icon (spec §7.6).
// ---------------------------------------------------------------------------

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4, vertical: Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.warningBg,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
            color: BrandColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: BrandColors.warning, size: Sizes.icon),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: BrandColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Capture frame — 3:2 aspect, radius Radii.xl, L-shaped lime corner brackets,
// caption in mutedFg, capture control = 72px primary circle + BrandShadows.glow.
// ---------------------------------------------------------------------------

class _CaptureFrame extends StatelessWidget {
  final XFile? file;
  final VoidCallback onTap;
  const _CaptureFrame({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: BrandColors.surface,
                borderRadius: BorderRadius.circular(Radii.xl),
              ),
              clipBehavior: Clip.antiAlias,
              child: file != null
                  ? Image.file(File(file!.path), fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 72px primary circle capture control with glow.
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: BrandColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: BrandShadows.glow,
                          ),
                          child: Icon(
                            Icons.photo_camera_outlined,
                            color: BrandColors.primaryFg,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: Spacing.x3),
                        // Caption in mutedFg (spec §7.6).
                        Text(
                          'Position front of license inside the frame',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: BrandColors.mutedFg),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
            // Lime L-shaped corner brackets drawn on top.
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _CornerBracketsPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem {
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;
  const _ChecklistItem({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });
}

class _ChecklistCard extends StatelessWidget {
  final List<_ChecklistItem> items;
  const _ChecklistCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: BrandColors.border),
            _row(context, items[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, _ChecklistItem item) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x4, vertical: Spacing.x4),
        child: Row(
          children: [
            Icon(
              item.done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.done ? BrandColors.primary : BrandColors.mutedFg,
              size: Sizes.icon,
            ),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: textTheme.bodySmall
                          ?.copyWith(color: BrandColors.mutedFg)),
                ],
              ),
            ),
            if (item.done)
              Text('DONE',
                  style: textTheme.labelMedium
                      ?.copyWith(color: BrandColors.primary))
            else
              Icon(Icons.chevron_right,
                  color: BrandColors.mutedFg, size: Sizes.icon),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              color: BrandColors.primary, size: Sizes.icon),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: BrandColors.mutedFg),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Primary CTA with glow — full pill (theme-driven), spec §shared rules.
// ---------------------------------------------------------------------------

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.pill),
        boxShadow: BrandShadows.glow,
      ),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.primaryFg,
                ),
              )
            : Text(label),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step header — circular chevron back + step label.
// ---------------------------------------------------------------------------

class _StepHeader extends StatelessWidget {
  final String label;
  const _StepHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          customBorder: const CircleBorder(),
          child: Container(
            width: Sizes.avatar,
            height: Sizes.avatar,
            decoration: BoxDecoration(
              color: BrandColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.border),
            ),
            child: Icon(Icons.chevron_left,
                color: BrandColors.foreground, size: Sizes.iconLg),
          ),
        ),
        const SizedBox(width: Spacing.x4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: BrandColors.mutedFg),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Paints four lime L-shaped corner brackets inset from the frame edges.
// ---------------------------------------------------------------------------

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BrandColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const inset = 14.0; // padding from the frame edge
    const len = 24.0; // bracket arm length

    // Top-left.
    canvas.drawLine(
        const Offset(inset, inset + len), const Offset(inset, inset), paint);
    canvas.drawLine(
        const Offset(inset, inset), const Offset(inset + len, inset), paint);

    // Top-right.
    canvas.drawLine(Offset(size.width - inset - len, inset),
        Offset(size.width - inset, inset), paint);
    canvas.drawLine(Offset(size.width - inset, inset),
        Offset(size.width - inset, inset + len), paint);

    // Bottom-left.
    canvas.drawLine(Offset(inset, size.height - inset - len),
        Offset(inset, size.height - inset), paint);
    canvas.drawLine(Offset(inset, size.height - inset),
        Offset(inset + len, size.height - inset), paint);

    // Bottom-right.
    canvas.drawLine(Offset(size.width - inset - len, size.height - inset),
        Offset(size.width - inset, size.height - inset), paint);
    canvas.drawLine(Offset(size.width - inset, size.height - inset - len),
        Offset(size.width - inset, size.height - inset), paint);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) => false;
}
