import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/kyc_service.dart';

/// Live KYC status for the current user.
final kycStatusProvider = FutureProvider.autoDispose<KycStatus>((ref) {
  return ref.watch(kycServiceProvider).status();
});

/// Driver's licence capture + KYC status.
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

  Future<void> _capture(void Function(XFile) assign, ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) setState(() => assign(file));
    } catch (_) {
      _snack('Could not access the camera/gallery.');
    }
  }

  Future<void> _submit() async {
    if (_front == null) {
      _snack('Capture the front of your licence first.');
      return;
    }
    setState(() => _busy = true);
    try {
      // In production the captured files are uploaded to R2 first; their public
      // URLs are then submitted here. That media pipeline is environment-specific.
      _snack('Document upload service is not configured in this build.');
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
      appBar: AppBar(title: const Text('Driver\'s licence')),
      body: AsyncValueView<KycStatus>(
        value: status,
        onRetry: () => ref.invalidate(kycStatusProvider),
        data: (kyc) => SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Verification status',
                      style: TextStyle(color: BrandColors.mutedFg)),
                  const Spacer(),
                  StatusChip.verification(kyc.status),
                ],
              ),
              const SizedBox(height: Spacing.x6),
              _DocTile(
                label: 'Front of licence',
                file: _front,
                onCapture: (s) => _capture((f) => _front = f, s),
              ),
              const SizedBox(height: Spacing.x4),
              _DocTile(
                label: 'Back of licence',
                file: _back,
                onCapture: (s) => _capture((f) => _back = f, s),
              ),
              const SizedBox(height: Spacing.x4),
              _DocTile(
                label: 'Selfie',
                file: _selfie,
                onCapture: (s) => _capture((f) => _selfie = f, s),
              ),
              const SizedBox(height: Spacing.x8),
              LoadingButton(
                label: 'Submit for review',
                loading: _busy,
                onPressed: kyc.isApproved ? null : _submit,
              ),
              if (kyc.isApproved)
                const Padding(
                  padding: EdgeInsets.only(top: Spacing.x4),
                  child: Center(
                    child: Text('Your licence is verified ✓',
                        style: TextStyle(color: BrandColors.success)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final String label;
  final XFile? file;
  final void Function(ImageSource) onCapture;

  const _DocTile({
    required this.label,
    required this.file,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.card),
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  onCapture(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  onCapture(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: file != null ? BrandColors.primary : BrandColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(file!.path), fit: BoxFit.cover),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.check_circle, color: BrandColors.primary),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: BrandColors.mutedFg),
                  const SizedBox(height: Spacing.x2),
                  Text(label,
                      style: const TextStyle(color: BrandColors.mutedFg)),
                ],
              ),
      ),
    );
  }
}
