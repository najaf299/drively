import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/car.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/providers/host_provider.dart';

/// The host's fleet of listed cars. Restyled to the Drivly dark premium system.
class HostCarsScreen extends ConsumerWidget {
  const HostCarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(hostCarsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/host/add-car'),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.primaryFg,
        icon: const Icon(Icons.add),
        label: const Text('Add car',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x4),
              child: Row(
                children: [
                  _CircleBackButton(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/host'),
                  ),
                  const SizedBox(width: Spacing.x4),
                  Expanded(
                    child: Text('My cars',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  cars.maybeWhen(
                    data: (list) => _CountPill(count: list.length),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView<List<Car>>(
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
                      padding: const EdgeInsets.fromLTRB(
                          Spacing.x5, 0, Spacing.x5, Spacing.x10),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacing.x4),
                      itemBuilder: (_, i) => CarCard(
                        car: list[i],
                        showStatus: true,
                        onTap: () => context.push('/car/${list[i].id}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BrandColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        '$count active',
        style: const TextStyle(
          color: BrandColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.border),
        ),
        child: const Icon(Icons.chevron_left,
            color: BrandColors.foreground, size: 26),
      ),
    );
  }
}
