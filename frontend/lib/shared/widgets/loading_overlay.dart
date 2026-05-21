import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Dims [child] and shows a centered spinner while [isLoading] is true.
///
/// Scrim uses [BrandColors.overlay] at 60 % opacity — no raw hex literals.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: BrandColors.overlay.withValues(alpha: 0.6),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
