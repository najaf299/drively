import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Tone of an [AppSnack] toast.
enum SnackType { success, info, warning, error }

/// Modern branded toast (spec §2 BrandSnackbar). Floating, rounded, with a
/// tonal background, a leading status icon and an optional action — replaces
/// the default grey Material SnackBar across the app.
class AppSnack {
  AppSnack._();

  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (bg, accent, defaultIcon) = _style(type);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        elevation: 0,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(
            Spacing.x4, 0, Spacing.x4, Spacing.x4),
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x4, vertical: Spacing.x3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon ?? defaultIcon, color: accent, size: 18),
            ),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BrandColors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: BrandColors.primary,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackType.error);

  /// Standard "coming soon" toast used for not-yet-built destinations.
  static void soon(BuildContext context) => show(
        context,
        'Coming soon — this is on the way.',
        type: SnackType.info,
        icon: Icons.rocket_launch_outlined,
      );

  static (Color bg, Color accent, IconData icon) _style(SnackType type) {
    switch (type) {
      case SnackType.success:
        return (
          BrandColors.successBg,
          BrandColors.success,
          Icons.check_circle_outline
        );
      case SnackType.warning:
        return (
          BrandColors.warningBg,
          BrandColors.warning,
          Icons.warning_amber_rounded
        );
      case SnackType.error:
        return (
          BrandColors.destructiveBg,
          BrandColors.destructive,
          Icons.error_outline
        );
      case SnackType.info:
        return (BrandColors.surface2, BrandColors.info, Icons.info_outline);
    }
  }
}
