import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/providers/car_provider.dart';

/// Map browse screen.
///
/// A full interactive map (`google_maps_flutter`) requires a platform Maps API
/// key; to keep the app runnable in any environment this presents the same
/// result set as location cards. Swap [_MapPlaceholder] for a `GoogleMap` once
/// a key is configured.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Map view')),
      body: Column(
        children: [
          const _MapPlaceholder(),
          Expanded(
            child: cars.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.map_outlined,
                    title: 'No cars in this area',
                    subtitle: 'Zoom out or change your filters.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(Spacing.x4),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Spacing.x3),
                  itemBuilder: (_, i) {
                    final car = list[i];
                    return Card(
                      child: ListTile(
                        onTap: () => context.push('/car/${car.id}'),
                        leading: AppNetworkImage(
                          url: car.coverPhotoUrl,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        title: Text(car.displayNameWithYear),
                        subtitle: Text(
                          car.distance != null
                              ? '${Formatters.distance(car.distance!)} · ${car.city}'
                              : car.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          Formatters.money(car.dailyPrice),
                          style: const TextStyle(
                            color: BrandColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      color: BrandColors.surface2,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 36, color: BrandColors.mutedFg),
          SizedBox(height: Spacing.x2),
          Text('Interactive map preview',
              style: TextStyle(color: BrandColors.mutedFg)),
        ],
      ),
    );
  }
}
