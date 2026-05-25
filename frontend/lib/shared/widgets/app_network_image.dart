import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Cached network image with branded illustration fallbacks.
///
/// Tolerates null/empty/broken URLs by rendering a designed placeholder tile —
/// a soft surface gradient with a centred brand-tinted [fallbackIcon] — so
/// missing media looks intentional rather than broken. No raw hex literals.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.directions_car_rounded,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = (url == null || url!.isEmpty)
        ? _placeholder()
        : CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => _placeholder(loading: true),
            errorWidget: (_, __, ___) => _placeholder(),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  /// Designed fallback: brand gradient + a glowing, tinted product icon.
  Widget _placeholder({bool loading = false}) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.surface3, BrandColors.surface2],
        ),
      ),
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: BrandColors.borderStrong,
              ),
            )
          : _Illustration(icon: fallbackIcon),
    );
  }
}

/// Centred icon inside a soft tinted disc — used as a default illustration.
class _Illustration extends StatelessWidget {
  final IconData icon;
  const _Illustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the icon to the tile; clamp for tiny/large thumbnails.
        final shortest = constraints.biggest.shortestSide;
        final size = shortest.isFinite
            ? (shortest * 0.34).clamp(20.0, 56.0)
            : 32.0;
        return Icon(
          icon,
          size: size,
          color: BrandColors.primary.withValues(alpha: 0.85),
        );
      },
    );
  }
}
