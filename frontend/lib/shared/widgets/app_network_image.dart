import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Cached network image with consistent placeholder/error fallbacks.
///
/// Tolerates null/empty URLs by rendering the [fallbackIcon] on a surface tile.
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
    this.fallbackIcon = Icons.directions_car_outlined,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = (url == null || url!.isEmpty)
        ? _placeholder(const Icon(Icons.image_not_supported_outlined,
            color: BrandColors.mutedFg))
        : CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => _placeholder(null),
            errorWidget: (_, __, ___) =>
                _placeholder(Icon(fallbackIcon, color: BrandColors.mutedFg)),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _placeholder(Widget? icon) => Container(
        width: width,
        height: height,
        color: BrandColors.surface2,
        alignment: Alignment.center,
        child: icon,
      );
}
