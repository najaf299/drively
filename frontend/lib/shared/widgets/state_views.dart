import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';

/// Centered loading spinner.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Error state — drivly Flutter Build Spec v2 §2 (ErrorView).
///
/// 96 px line-icon on a surface circle (destructive tint), headlineSmall title,
/// bodyMedium muted body, optional tonal OutlinedButton.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: BrandColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: BrandColors.destructive,
              ),
            ),
            const SizedBox(height: Spacing.x4),
            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: text.headlineSmall,
            ),
            const SizedBox(height: Spacing.x2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: BrandColors.mutedFg),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.x5),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state — drivly Flutter Build Spec v2 §2 (EmptyState).
///
/// 96 px line-icon on a surface circle (primary tint), headlineSmall title,
/// bodyMedium muted subtitle, optional tonal OutlinedButton CTA.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final content = Padding(
      padding: const EdgeInsets.all(Spacing.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: BrandColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: BrandColors.primary),
          ),
          const SizedBox(height: Spacing.x4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: Spacing.x2),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: BrandColors.mutedFg),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Spacing.x5),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );

    // Stay centered when there's room, but scroll instead of overflowing when
    // the available height is short (e.g. a tab pane on a small screen).
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) return Center(child: content);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

/// Renders an [AsyncValue] as loading / error (with retry) / data, removing the
/// `.when(...)` boilerplate from every screen.
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: onRetry),
    );
  }
}
