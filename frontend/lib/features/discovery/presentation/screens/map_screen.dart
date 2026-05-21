import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/car.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/providers/car_provider.dart';

/// Map browse screen — spec §5, §7.9.
///
/// Full-screen styled map canvas with price-pin markers; user-location dot is
/// [BrandColors.primary] (spec §5.2). My-location FAB = 44 surface2/border.
/// Bottom [DraggableScrollableSheet] with a [CarCard] pager when a pin is
/// selected, or a mini-card summary strip when nothing is selected.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _selectedId;
  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cars = ref.watch(carListProvider);
    return Scaffold(
      body: cars.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) {
          final selected = list.where((c) => c.id == _selectedId).isNotEmpty
              ? list.firstWhere((c) => c.id == _selectedId)
              : null;

          return Stack(
            children: [
              // ── Map canvas ───────────────────────────────────────────────
              Positioned.fill(
                child: _MapCanvas(
                  cars: list,
                  selectedId: _selectedId,
                  onTapMarker: (id) => setState(
                      () => _selectedId = _selectedId == id ? null : id),
                ),
              ),

              // ── Floating top bar: back + search pill + layers ────────────
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
                            height: Sizes.searchBar,
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.x4),
                            decoration: BoxDecoration(
                              color: BrandColors.surface2,
                              borderRadius:
                                  BorderRadius.circular(Radii.pill),
                              border: Border.all(color: BrandColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search,
                                    color: BrandColors.mutedFg,
                                    size: Sizes.iconSm),
                                const SizedBox(width: Spacing.x2),
                                Expanded(
                                  child: Text(
                                    'Cars near ${_areaLabel(list)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
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

              // ── My-location FAB (44 dp, surface2/border) ─────────────────
              Positioned(
                right: Spacing.x4,
                bottom: selected != null ? 220 : 100,
                child: _LocateFab(onTap: () {}),
              ),

              // ── Empty state overlay ──────────────────────────────────────
              if (list.isEmpty)
                const Center(
                  child: EmptyView(
                    icon: Icons.map_outlined,
                    title: 'No cars in this area',
                    subtitle: 'Zoom out or change your filters.',
                  ),
                ),

              // ── Bottom draggable sheet with CarCard pager ────────────────
              if (list.isNotEmpty)
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: selected != null ? 0.38 : 0.14,
                  minChildSize: 0.10,
                  maxChildSize: 0.75,
                  snap: true,
                  snapSizes: const [0.14, 0.38, 0.75],
                  builder: (_, scrollController) =>
                      _BottomCarSheet(
                        cars: list,
                        selectedCar: selected,
                        scrollController: scrollController,
                        onView: (id) => context.push('/car/$id'),
                        onDismiss: () =>
                            setState(() => _selectedId = null),
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

// ── Bottom draggable sheet ────────────────────────────────────────────────────

class _BottomCarSheet extends StatelessWidget {
  final List<Car> cars;
  final Car? selectedCar;
  final ScrollController scrollController;
  final ValueChanged<String> onView;
  final VoidCallback onDismiss;

  const _BottomCarSheet({
    required this.cars,
    required this.selectedCar,
    required this.scrollController,
    required this.onView,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.xxl)),
        boxShadow: BrandShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle.
          Padding(
            padding: const EdgeInsets.only(
                top: Spacing.x3, bottom: Spacing.x2),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.borderStrong,
                borderRadius:
                    BorderRadius.circular(Radii.pill),
              ),
            ),
          ),
          // Header row.
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, 0, Spacing.x5, Spacing.x3),
            child: Row(
              children: [
                Text(
                  selectedCar != null
                      ? selectedCar!.displayName
                      : '${cars.length} cars nearby',
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (selectedCar != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(Icons.close,
                        size: Sizes.iconSm,
                        color: BrandColors.mutedFg),
                  ),
              ],
            ),
          ),
          // CarCard pager (horizontal for selected, vertical list otherwise).
          Expanded(
            child: selectedCar != null
                ? _CarPager(
                    cars: cars,
                    initialId: selectedCar!.id,
                    onView: onView,
                    scrollController: scrollController,
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.x4, 0, Spacing.x4, Spacing.x5),
                    itemCount: cars.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacing.x3),
                    itemBuilder: (_, i) => CarCard(
                      car: cars[i],
                      onTap: () => onView(cars[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Car horizontal pager ─────────────────────────────────────────────────────

class _CarPager extends StatefulWidget {
  final List<Car> cars;
  final String initialId;
  final ValueChanged<String> onView;
  final ScrollController scrollController;

  const _CarPager({
    required this.cars,
    required this.initialId,
    required this.onView,
    required this.scrollController,
  });

  @override
  State<_CarPager> createState() => _CarPagerState();
}

class _CarPagerState extends State<_CarPager> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final idx = widget.cars.indexWhere((c) => c.id == widget.initialId);
    _pageController = PageController(
      initialPage: idx < 0 ? 0 : idx,
      viewportFraction: 0.88,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.cars.length,
      itemBuilder: (_, i) {
        final car = widget.cars[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.x2),
          child: _MapCarCard(
            car: car,
            onView: () => widget.onView(car.id),
          ),
        );
      },
    );
  }
}

/// Compact map card for the pager.
class _MapCarCard extends StatelessWidget {
  final Car car;
  final VoidCallback onView;

  const _MapCarCard({required this.car, required this.onView});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.x4),
      padding: const EdgeInsets.all(Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.surface2,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: BrandColors.border),
        boxShadow: BrandShadows.card,
      ),
      child: Row(
        children: [
          AppNetworkImage(
            url: car.coverPhotoUrl,
            width: 80,
            height: 80,
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
                  style: text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.x1),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: BrandColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      car.averageRating.toStringAsFixed(1),
                      style: text.titleSmall,
                    ),
                    const SizedBox(width: Spacing.x1),
                    Flexible(
                      child: Text(
                        '· ${car.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.x2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: Formatters.money(car.dailyPrice),
                        style: text.titleMedium
                            ?.copyWith(color: BrandColors.primary),
                      ),
                      TextSpan(text: '/day', style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x2),
          FilledButton(
            onPressed: onView,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, Sizes.filterChip),
              padding:
                  const EdgeInsets.symmetric(horizontal: Spacing.x4),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

// ── Map canvas (styled stand-in until Google Maps key is set) ────────────────

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
              // Stylised street map (roads, water, parks) — dark map palette.
              const Positioned.fill(
                  child: CustomPaint(painter: _MapPainter())),

              // Price markers — deterministically scattered.
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

              // User-location dot — primary (spec §5.2).
              Positioned(
                left: w * 0.5 - 9,
                top: h * 0.55 - 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft halo.
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: BrandColors.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // 16 dp dot.
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: BrandColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: BrandColors.background, width: 3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _scatterX(int i, int n, double w) {
    final cols = n <= 1 ? 1 : 3;
    final col = i % cols;
    final frac = cols == 1 ? 0.5 : 0.18 + col * 0.32;
    final jitter = ((i * 37) % 11 - 5) * 0.012;
    return (frac + jitter).clamp(0.06, 0.82) * w;
  }

  double _scatterY(int i, int n, double h) {
    final cols = n <= 1 ? 1 : 3;
    final row = i ~/ cols;
    final frac = 0.16 + (row * 0.16);
    final jitter = ((i * 53) % 9 - 4) * 0.014;
    return ((frac + jitter) % 0.78 + 0.12).clamp(0.12, 0.74) * h;
  }
}

// ── Price pill marker ────────────────────────────────────────────────────────

/// Active = primary pill with glow; inactive = surface2 with border.
/// Selected pin scales up per spec §5.
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
    final bg = selected ? BrandColors.primary : BrandColors.surface2;
    final fg = selected ? BrandColors.primaryFg : BrandColors.foreground;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Radii.pill),
            border:
                selected ? null : Border.all(color: BrandColors.border),
            boxShadow: selected ? BrandShadows.glow : null,
          ),
          child: Text(
            Formatters.moneyCompact(price),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}

// ── My-location FAB ──────────────────────────────────────────────────────────

/// 44 dp circular surface2/border button with target icon — spec §5.
class _LocateFab extends StatelessWidget {
  final VoidCallback onTap;

  const _LocateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface2,
      shape: const CircleBorder(
          side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: Sizes.iconRoundButton,
          height: Sizes.iconRoundButton,
          child: Icon(Icons.my_location,
              color: BrandColors.primary, size: Sizes.iconSm),
        ),
      ),
    );
  }
}

// ── Circle icon button ───────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface2,
      shape: const CircleBorder(
          side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: Sizes.iconRoundButton,
          height: Sizes.iconRoundButton,
          child: Icon(icon,
              color: BrandColors.foreground, size: Sizes.iconSm),
        ),
      ),
    );
  }
}

// ── Stylised map painter ─────────────────────────────────────────────────────

/// Paints a believable dark street map: a river, a park, a fine minor-street
/// grid, and a few major arterials/diagonals — so the screen reads as a real
/// map for the prototype (no Google Maps key required). Deterministic.
class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Water (river) — soft band sweeping the lower-left ──
    final water = Paint()..color = BrandColors.info.withValues(alpha: 0.08);
    final river = Path()
      ..moveTo(0, h * 0.60)
      ..quadraticBezierTo(w * 0.22, h * 0.72, w * 0.40, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(river, water);

    // ── Park — rounded block, upper-right ──
    final park = Paint()..color = BrandColors.success.withValues(alpha: 0.07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.60, h * 0.10, w * 0.32, h * 0.20),
        const Radius.circular(18),
      ),
      park,
    );

    // ── Minor street grid (fine hairlines) ──
    final minor = Paint()
      ..color = BrandColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const step = 64.0;
    for (double x = step; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), minor);
    }
    for (double y = step; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), minor);
    }

    // ── Secondary roads (mid weight) ──
    final mid = Paint()
      ..color = BrandColors.surface3.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * 0.66), Offset(w, h * 0.60), mid);
    canvas.drawLine(Offset(w * 0.74, 0), Offset(w * 0.80, h), mid);

    // ── Major arterials + a diagonal highway (heavy) ──
    final major = Paint()
      ..color = BrandColors.surface3
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * 0.34), Offset(w, h * 0.30), major);
    canvas.drawLine(Offset(w * 0.42, 0), Offset(w * 0.50, h), major);
    canvas.drawLine(Offset(w * 0.08, 0), Offset(w, h * 0.86), major);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
