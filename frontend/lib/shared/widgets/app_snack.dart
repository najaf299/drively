import 'package:flutter/material.dart';

import 'drivly_toast.dart';

/// Tone of a toast.
enum SnackType { success, info, warning, error }

/// Compatibility wrapper: routes the app's existing snackbar calls through the
/// new [DrivlyToast] system (Build Spec v3 §4). The `context` argument is kept
/// for source compatibility but is no longer required.
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
    final action = actionLabel != null
        ? ToastAction(actionLabel, onTap: onAction ?? () {})
        : null;
    switch (type) {
      case SnackType.success:
        DrivlyToast.success(message, action: action, icon: icon);
      case SnackType.warning:
        DrivlyToast.warning(message, action: action, icon: icon);
      case SnackType.error:
        DrivlyToast.error(message, action: action, icon: icon);
      case SnackType.info:
        DrivlyToast.info(message, action: action, icon: icon);
    }
  }

  static void success(BuildContext context, String message) =>
      DrivlyToast.success(message);

  static void error(BuildContext context, String message) =>
      DrivlyToast.error(message);

  /// Standard "coming soon" toast used for not-yet-built destinations.
  static void soon(BuildContext context) => DrivlyToast.info(
        'Coming soon — this is on the way.',
        icon: Icons.rocket_launch_outlined,
      );
}
