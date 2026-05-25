import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Circular avatar — photo or initials fallback.
///
/// Spec: circular with a 2 px [BrandColors.surface] ring; honours [radius].
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final inner = _inner();
    // 2 px surface ring around the avatar.
    return Container(
      width: radius * 2 + 4,
      height: radius * 2 + 4,
      decoration: BoxDecoration(
        color: BrandColors.surface,
        shape: BoxShape.circle,
      ),
      child: Center(child: inner),
    );
  }

  Widget _inner() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: BrandColors.surface2,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: BrandColors.surface2,
      child: Text(
        initials,
        style: TextStyle(
          color: BrandColors.foreground,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
