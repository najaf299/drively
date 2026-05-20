import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/car.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/providers/car_provider.dart';

/// Map browse screen.
///
/// A full interactive map (`google_maps_flutter`) requires a platform Maps API
/// key; to keep the app runnable in any environment this presents the same
/// result set over a styled map surface with price markers. Swap
/// [_MapCanvas] for a `GoogleMap` once a key is configured.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final cars = ref.watch(carListProvider);
    return Scaffold(
      body: cars.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) {
          // Keep selection valid as the list changes.
          final selected = list.where((c) => c.id == _selectedId).isNotEmpty
              ? list.firstWhere((c) => c.id == _selectedId)
              : null;
          return Stack(
            children: [
              _MapCanvas(
                cars: list,
                selectedId: _selectedId,
                onTapMarker: (id) => setState(() => _selectedId = id),
              ),
              // ── Floating top search bar + layers button ─────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.x4, Spacing.x3, Spacing.x4, 0),
                    child: Row(
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_back,
                          onTap: () => context.pop(),
                        ),
                        const SizedBox(width: Spacing.x3),
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.x4),
                            decoration: BoxDecoration(
                              color: BrandColors.surface,
                              borderRadius: BorderRadius.circular(Radii.pill),
                              border: Border.all(color: BrandColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search,
                                    color: BrandColors.mutedFg, size: 20),
                                const SizedBox(width: Spacing.x2),
                                Expanded(
                                  child: Text(
                                    'Cars near ${_areaLabel(list)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: BrandColors.foreground),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.x3),
                        _CircleButton(
                          icon: Icons.layers_outlined,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Zoom + locate controls ──────────────────────────────────
              Positioned(
                right: Spacing.x4,
                bottom: selected != null ? 200 : Spacing.x6,
                child: Column(
                  children: [
                    _MapControl(
                      icon: Icons.add,
                      onTap: () {},
                      top: true,
                    ),
                    Container(
                        width: 44, height: 1, color: BrandColors.border),
                    _MapControl(
                      icon: Icons.remove,
                      onTap: () {},
                      bottom: true,
                    ),
                    const SizedBox(height: Spacing.x3),
                    _LocateFab(onTap: () {}),
                  ],
                ),
              ),
              // ── Bottom selected-car card ────────────────────────────────
              if (selected != null)
                Positioned(
                  left: Spacing.x4,
                  right: Spacing.x4,
                  bottom: Spacing.x4,
                  child: SafeArea(
                    top: false,
                    child: _SelectedCarCard(
                      car: selected,
                      onView: () => context.push('/car/${selected.id}'),
                    ),
                  ),
                ),
              if (list.isEmpty)
                const Center(
                  child: EmptyView(
                    icon: Icons.map_outlined,
                    title: 'No cars in this area',
                    subtitle: 'Zoom out or change your filters.',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _areaLabel(List<Car> cars) =>
      cars.isNotEmpty ? cars.first.city : 'you';
}

/// Styled stand-in map surface that scatters price markers across the canvas.
class _MapCanvas extends StatelessWidget {
  final List<Car> cars;
  final String? selectedId;
  final ValueChanged<String> onTapMarker;

  const _MapCanvas({
    required this.cars,
    required this.selectedId,
    required this.onTapMarker,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Container(
          width: w,
          height: h,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [BrandColors.surface2, BrandColors.background],
            ),
          ),
          child: Stack(
            children: [
              // Subtle "grid" texture so it reads as a map surface.
              const Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),
              // Price markers, deterministically scattered.
              for (var i = 0; i < cars.length; i++)
                Positioned(
                  left: _scatterX(i, cars.length, w),
                  top: _scatterY(i, cars.length, h),
                  child: _PriceMarker(
                    price: cars[i].dailyPrice,
                    selected: cars[i].id == selectedId,
                    onTap: () => onTapMarker(cars[i].id),
                  ),
                ),
              // The user's own location marker (coral).
              Positioned(
                left: w * 0.5 - 9,
                top: h * 0.55 - 9,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: BrandColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _scatterX(int i, int n, double w) {
    final cols = (n <= 1) ? 1 : 3;
    final col = i % cols;
    final frac = cols == 1 ? 0.5 : 0.18 + col * 0.32;
    final jitter = ((i * 37) % 11 - 5) * 0.012;
    return (frac + jitter).clamp(0.06, 0.82) * w;
  }

  double _scatterY(int i, int n, double h) {
    final cols = (n <= 1) ? 1 : 3;
    final row = i ~/ cols;
    final frac = 0.16 + (row * 0.16);
    final jitter = ((i * 53) % 9 - 4) * 0.014;
    return ((frac + jitter) % 0.78 + 0.12).clamp(0.12, 0.74) * h;
  }
}

/// Lime price pill marker; coral when selected.
class _PriceMarker extends StatelessWidget {
  final double price;
  final bool selected;
  final VoidCallback onTap;
  const _PriceMarker({
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? BrandColors.accent : BrandColors.primary;
    final fg = selected ? Colors.white : BrandColors.primaryFg;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.pill),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          Formatters.moneyCompact(price),
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Compact map card for the currently selected car.
class _SelectedCarCard extends StatelessWidget {
  final Car car;
  final VoidCallback onView;
  const _SelectedCarCard({required this.car, required this.onView});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          AppNetworkImage(
            url: car.coverPhotoUrl,
            width: 72,
            height: 72,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  car.displayName,
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: BrandColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      car.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        car.distance != null
                            ? '· ${Formatters.distance(car.distance!)} away · ${car.city}'
                            : '· ${car.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: BrandColors.mutedFg, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: Formatters.money(car.dailyPrice),
                        style: const TextStyle(
                          color: BrandColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const TextSpan(
                        text: '/day',
                        style: TextStyle(
                            color: BrandColors.mutedFg, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x2),
          SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: onView,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.x5),
              ),
              child: const Text('View'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BrandColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const step = 56.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 44px circular icon button on a surface tile (top overlays).
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: const CircleBorder(side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: BrandColors.foreground, size: 20),
        ),
      ),
    );
  }
}

/// A stacked zoom control button (rounded on the outer edge).
class _MapControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool top;
  final bool bottom;
  const _MapControl({
    required this.icon,
    required this.onTap,
    this.top = false,
    this.bottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: Radius.circular(top ? Radii.md : 0),
      bottom: Radius.circular(bottom ? Radii.md : 0),
    );
    return Material(
      color: BrandColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: BrandColors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: BrandColors.foreground, size: 22),
        ),
      ),
    );
  }
}

/// Lime locate FAB.
class _LocateFab extends StatelessWidget {
  final VoidCallback onTap;
  const _LocateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.my_location, color: BrandColors.primaryFg),
        ),
      ),
    );
  }
}
