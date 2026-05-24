import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Canonical action row for every confirmation/input dialog in the app so the
/// Cancel button looks and behaves identically everywhere.
///
/// Layout: two equal-width pill buttons — a tonal [OutlinedButton] "Cancel" on
/// the left and a [FilledButton] primary action on the right (destructive tint
/// when [destructive] is set). Pair it with [kDialogActionsPadding] in the
/// host `AlertDialog.actionsPadding`.
class DialogActions extends StatelessWidget {
  /// Left/dismiss button label. Always defaults to 'Cancel' for consistency.
  final String cancelLabel;

  /// Right/confirm button label.
  final String confirmLabel;

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  /// Tints the confirm button destructive (red) for irreversible actions.
  final bool destructive;

  const DialogActions({
    super.key,
    this.cancelLabel = 'Cancel',
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel — tonal outlined, equal width/height. The single source of
        // truth for the app's Cancel button styling.
        Expanded(
          child: SizedBox(
            height: Sizes.secondaryHeight,
            child: OutlinedButton(
              onPressed: onCancel,
              child: Text(cancelLabel),
            ),
          ),
        ),
        const SizedBox(width: Spacing.x3),
        // Confirm — primary (or destructive), equal width/height.
        Expanded(
          child: SizedBox(
            height: Sizes.secondaryHeight,
            child: FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: BrandColors.destructive,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(Sizes.secondaryHeight),
                    )
                  : null,
              onPressed: onConfirm,
              child: Text(confirmLabel),
            ),
          ),
        ),
      ],
    );
  }
}

/// Standard padding around [DialogActions] inside an [AlertDialog].
const EdgeInsets kDialogActionsPadding =
    EdgeInsets.fromLTRB(Spacing.x5, Spacing.x2, Spacing.x5, Spacing.x5);

/// Shows a brand-consistent confirm dialog and resolves to `true` when the
/// confirm button is tapped (and `false`/`null` otherwise).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: kDialogActionsPadding,
      actions: [
        DialogActions(
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          destructive: destructive,
          onCancel: () => Navigator.pop(ctx, false),
          onConfirm: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return result ?? false;
}
