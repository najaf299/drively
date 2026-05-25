import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// Personal info / edit profile (spec §6 profile edit). Loads the current user,
/// lets them edit name, phone and bio, and persists via the real PUT /profile
/// endpoint through [AuthNotifier.updateProfile].
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  bool _saving = false;
  File? _avatarFile; // a newly picked photo, pending upload on save
  bool _removePhoto = false; // user chose to clear an existing server photo

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// Pick a new profile photo from the camera or library (or remove it).
  /// The chosen file is previewed locally and uploaded when the user taps Save.
  Future<void> _changePhoto() async {
    FocusScope.of(context).unfocus();
    final hasPhoto = _avatarFile != null ||
        ((ref.read(authProvider).user?.avatarUrl?.isNotEmpty ?? false) &&
            !_removePhoto);
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: BrandColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.x3),
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: Spacing.x2),
              decoration: BoxDecoration(
                color: BrandColors.borderStrong,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: BrandColors.primary),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: BrandColors.primary),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: BrandColors.destructive),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            const SizedBox(height: Spacing.x2),
          ],
        ),
      ),
    );
    if (action == null) return;
    if (action == 'remove') {
      setState(() {
        _avatarFile = null;
        _removePhoto = true;
      });
      return;
    }
    final source =
        action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _avatarFile = File(picked.path);
          _removePhoto = false;
        });
      }
    } catch (_) {
      if (mounted) AppSnack.error(context, 'Could not open the camera or library.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final notifier = ref.read(authProvider.notifier);

      // Upload a newly picked photo first so its URL is persisted on the user.
      if (_avatarFile != null) {
        await notifier.uploadAvatar(_avatarFile!);
      }

      await notifier.updateProfile({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'bio': _bio.text.trim(),
        if (_removePhoto && _avatarFile == null) 'avatar_url': null,
      });
      if (!mounted) return;
      setState(() {
        _avatarFile = null;
        _removePhoto = false;
      });
      AppSnack.success(context, 'Profile updated.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Could not update profile.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final text = Theme.of(context).textTheme;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
            children: [
              // Header
              Row(
                children: [
                  _BackButton(),
                  const SizedBox(width: Spacing.x4),
                  Text('Personal info', style: text.headlineMedium),
                ],
              ),
              const SizedBox(height: Spacing.x6),
              // Avatar + change photo
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: Sizes.avatarXl,
                          height: Sizes.avatarXl,
                          decoration: const BoxDecoration(
                            color: BrandColors.primary,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _avatarFile != null
                              ? Image.file(_avatarFile!, fit: BoxFit.cover)
                              : (!_removePhoto &&
                                      (user.avatarUrl?.isNotEmpty ?? false))
                                  ? Image.network(user.avatarUrl!,
                                      fit: BoxFit.cover)
                                  : Center(
                                      child: Text(user.initials,
                                          style: text.headlineLarge?.copyWith(
                                              color: BrandColors.primaryFg)),
                                    ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _changePhoto,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: BrandColors.surface3,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: BrandColors.background, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  size: 16, color: BrandColors.foreground),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.x3),
                    if (user.isKycApproved)
                      const StatusBadge('VERIFIED',
                          tone: BadgeTone.success, icon: Icons.verified),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.x6),
              // Full name
              const _Label('Full name'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                validator: Validators.name,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Your full name',
                ),
              ),
              const SizedBox(height: Spacing.x4),
              // Email (read-only)
              const _Label('Email'),
              TextFormField(
                initialValue: user.email,
                enabled: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  suffixIcon: Icon(Icons.lock_outline, size: Sizes.iconSm),
                ),
              ),
              const SizedBox(height: 4),
              Text('Email can’t be changed here.',
                  style: text.bodySmall),
              const SizedBox(height: Spacing.x4),
              // Phone
              const _Label('Phone'),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+15551234567',
                ),
              ),
              const SizedBox(height: Spacing.x4),
              // Bio
              const _Label('Bio'),
              TextFormField(
                controller: _bio,
                maxLines: 4,
                maxLength: 240,
                decoration: const InputDecoration(
                  hintText: 'Tell hosts and guests a little about you…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: Spacing.x4),
              // Save
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BrandColors.primaryFg,
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Spacing.x1, bottom: Spacing.x2),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: BrandColors.mutedFg),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: const CircleBorder(side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child:
              Icon(Icons.arrow_back, color: BrandColors.foreground, size: 20),
        ),
      ),
    );
  }
}
