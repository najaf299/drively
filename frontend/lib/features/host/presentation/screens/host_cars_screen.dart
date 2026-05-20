import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/car.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/providers/host_provider.dart';

/// The host's fleet of listed cars.
class HostCarsScreen extends ConsumerWidget {
  const HostCarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(hostCarsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My cars')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/host/add-car'),
        icon: const Icon(Icons.add),
        label: const Text('Add car'),
      ),
      body: AsyncValueView<List<Car>>(
        value: cars,
        onRetry: () => ref.invalidate(hostCarsProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.directions_car_outlined,
              title: 'No cars listed yet',
              subtitle: 'List your first car to start earning.',
              actionLabel: 'Add a car',
              onAction: () => context.push('/host/add-car'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(hostCarsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(Spacing.x5),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.x4),
              itemBuilder: (_, i) => CarCard(
                car: list[i],
                showStatus: true,
                onTap: () => context.push('/car/${list[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
