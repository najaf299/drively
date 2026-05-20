import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Circular avatar that shows the user's photo, or their initials on a brand
/// surface when no photo is available.
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
