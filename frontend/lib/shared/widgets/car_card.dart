import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarCard extends StatelessWidget {
  final String imageUrl;
  final String make;
  final String model;
  final int year;
  final double dailyPrice;
  final double rating;
  final VoidCallback? onTap;

  const CarCard({
    super.key,
    required this.imageUrl,
    required this.make,
    required this.model,
    required this.year,
    required this.dailyPrice,
    this.rating = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$make \$model', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$year', style: Theme.of(context).textTheme.bodySmall),
                      Text('\$\${dailyPrice.toStringAsFixed(0)}/day',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
