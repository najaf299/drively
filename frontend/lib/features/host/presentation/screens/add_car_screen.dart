import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../data/host_service.dart';
import '../../domain/providers/host_provider.dart';

/// Single-screen car listing form (covers the required `POST /host/cars` fields).
///
/// Restyled to the Drivly "List your car" design: a step progress bar, a dashed
/// photo-upload box, floating-label rounded fields, a smart-pricing block and a
/// full-width lime "Continue" button. All form fields, controllers, validation
/// and the submit payload are preserved.
class AddCarScreen extends ConsumerStatefulWidget {
  const AddCarScreen({super.key});

  @override
  ConsumerState<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends ConsumerState<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: '2022');
  final _plate = TextEditingController();
  final _price = TextEditingController();
  final _seats = TextEditingController(text: '5');
  final _doors = TextEditingController(text: '4');
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController(text: 'AE');
  final _lat = TextEditingController(text: '25.2048');
  final _lng = TextEditingController(text: '55.2708');
  final _description = TextEditingController();

  String _transmission = 'automatic';
  String _fuelType = 'petrol';
  String _fuelPolicy = 'full_to_full';
  final _features = <String>{'ac'};
  bool _busy = false;

  // Presentational smart-pricing state. Mirrors the [_price] controller so the
  // submit payload is unchanged.
  bool _dynamicPricing = true;
  double _basePrice = 78;

  static const _featureOptions = {
    'ac': 'Air conditioning',
    'bluetooth': 'Bluetooth',
    'gps': 'GPS',
    'sunroof': 'Sunroof',
    'child_seat': 'Child seat',
    'apple_carplay': 'Apple CarPlay',
    'usb': 'USB',
  };

  @override
  void initState() {
    super.initState();
    final parsed = double.tryParse(_price.text);
    if (parsed != null && parsed > 0) _basePrice = parsed.clamp(20, 300);
    _price.text = _basePrice.round().toString();
  }

  @override
  void dispose() {
    for (final c in [
      _make,
      _model,
      _year,
      _plate,
      _price,
      _seats,
      _doors,
      _address,
      _city,
      _country,
      _lat,
      _lng,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_features.isEmpty) {
      _snack('Select at least one feature.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(hostServiceProvider).createCar({
        'make': _make.text.trim(),
        'model': _model.text.trim(),
        'year': int.tryParse(_year.text) ?? DateTime.now().year,
        'plate_number': _plate.text.trim(),
        'transmission': _transmission,
        'fuel_type': _fuelType,
        'seats': int.tryParse(_seats.text) ?? 5,
        'doors': int.tryParse(_doors.text) ?? 4,
        'daily_price': double.tryParse(_price.text) ?? 0,
        'features': _features.toList(),
        'lat': double.tryParse(_lat.text) ?? 0,
        'lng': double.tryParse(_lng.text) ?? 0,
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'country': _country.text.trim().toUpperCase(),
        'fuel_policy': _fuelPolicy,
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
      });
      ref.invalidate(hostCarsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Car listed successfully.')));
        context.pop();
      }
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x3),
                child: Row(
                  children: [
                    _CircleBackButton(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/host'),
                    ),
                    const SizedBox(width: Spacing.x4),
                    Expanded(
                      child: Text(
                        'List your car',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(Spacing.x5, 0, Spacing.x5, 0),
                child: _StepProgress(step: 1, total: 5),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, Spacing.x5, Spacing.x5, Spacing.x6),
                  children: [
                    const _PhotoUploadBox(),
                    const SizedBox(height: Spacing.x6),
                    _section('Basics'),
                    _field(_make, 'Make',
                        validator: (v) => Validators.required(v, 'Make')),
                    _field(_model, 'Model',
                        validator: (v) => Validators.required(v, 'Model')),
                    Row(children: [
                      Expanded(
                          child: _field(_year, 'Year',
                              keyboard: TextInputType.number)),
                      const SizedBox(width: Spacing.x3),
                      Expanded(
                          child: _field(_plate, 'License plate',
                              validator: (v) =>
                                  Validators.required(v, 'Plate'))),
                    ]),
                    Row(children: [
                      Expanded(
                          child: _dropdown(
                              'Gearbox',
                              _transmission,
                              const {
                                'automatic': 'Automatic',
                                'manual': 'Manual',
                              },
                              (v) => setState(() => _transmission = v))),
                      const SizedBox(width: Spacing.x3),
                      Expanded(
                          child: _dropdown(
                              'Fuel',
                              _fuelType,
                              const {
                                'petrol': 'Petrol',
                                'diesel': 'Diesel',
                                'electric': 'Electric',
                                'hybrid': 'Hybrid',
                              },
                              (v) => setState(() => _fuelType = v))),
                    ]),
                    Row(children: [
                      Expanded(
                          child: _field(_seats, 'Seats',
                              keyboard: TextInputType.number)),
                      const SizedBox(width: Spacing.x3),
                      Expanded(
                          child: _field(_doors, 'Doors',
                              keyboard: TextInputType.number)),
                    ]),
                    _section('Smart pricing'),
                    _SmartPricing(
                      enabled: _dynamicPricing,
                      onToggle: (v) => setState(() => _dynamicPricing = v),
                      basePrice: _basePrice,
                      onPriceChanged: (v) => setState(() {
                        _basePrice = v;
                        _price.text = v.round().toString();
                      }),
                    ),
                    // Hidden-but-validated price field keeps the original
                    // controller, validation and submit payload intact.
                    _field(_price, 'Daily price (\$)',
                        keyboard: TextInputType.number,
                        validator: (v) => Validators.required(v, 'Price')),
                    _section('Location'),
                    _field(_address, 'Address',
                        validator: (v) => Validators.required(v, 'Address')),
                    Row(children: [
                      Expanded(
                          child: _field(_city, 'City',
                              validator: (v) =>
                                  Validators.required(v, 'City'))),
                      const SizedBox(width: Spacing.x3),
                      SizedBox(
                        width: 90,
                        child: _field(_country, 'Country',
                            validator: (v) =>
                                Validators.required(v, 'Country')),
                      ),
                    ]),
                    Row(children: [
                      Expanded(
                          child: _field(_lat, 'Latitude',
                              keyboard: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true))),
                      const SizedBox(width: Spacing.x3),
                      Expanded(
                          child: _field(_lng, 'Longitude',
                              keyboard: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true))),
                    ]),
                    _section('Features'),
                    Wrap(
                      spacing: Spacing.x2,
                      runSpacing: Spacing.x1,
                      children: _featureOptions.entries.map((e) {
                        final sel = _features.contains(e.key);
                        return FilterChip(
                          label: Text(e.value),
                          selected: sel,
                          onSelected: (_) => setState(() => sel
                              ? _features.remove(e.key)
                              : _features.add(e.key)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: Spacing.x4),
                    _dropdown(
                        'Fuel policy',
                        _fuelPolicy,
                        const {
                          'full_to_full': 'Full to full',
                          'full_to_empty': 'Full to empty',
                          'same_level': 'Same level',
                        },
                        (v) => setState(() => _fuelPolicy = v)),
                    _section('Description'),
                    _field(_description, 'Tell renters about your car',
                        maxLines: 4),
                    const SizedBox(height: Spacing.x6),
                    _PrimaryButton(
                      label: 'Continue',
                      loading: _busy,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, Spacing.x4, 0, Spacing.x3),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.x3),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        inputFormatters: keyboard == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            borderSide: const BorderSide(color: BrandColors.surface2, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            borderSide: const BorderSide(color: BrandColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> options,
      ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.x3),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            borderSide: const BorderSide(color: BrandColors.surface2, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            borderSide: const BorderSide(color: BrandColors.primary, width: 2),
          ),
        ),
        dropdownColor: BrandColors.surface,
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}

/// "Step X of 5" lime progress bar.
class _StepProgress extends StatelessWidget {
  final int step;
  final int total;
  const _StepProgress({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $step of $total',
          style: const TextStyle(
            color: BrandColors.mutedFg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.x2),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: step / total,
            minHeight: 8,
            backgroundColor: BrandColors.surface2,
            color: BrandColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Dashed photo-upload box with a camera icon.
class _PhotoUploadBox extends StatelessWidget {
  const _PhotoUploadBox();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: BrandColors.surface2,
        radius: Radii.card,
      ),
      child: Container(
        height: 168,
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BrandColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_outlined,
                  color: BrandColors.primary, size: 26),
            ),
            const SizedBox(height: Spacing.x3),
            const Text(
              'Add 6+ photos',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 2),
            const Text(
              'High quality, daylight',
              style: TextStyle(color: BrandColors.mutedFg, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(
          metric.extractPath(dist, next.clamp(0, metric.length)),
          paint,
        );
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Smart-pricing block: AI dynamic toggle card + base price slider + rules.
class _SmartPricing extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final double basePrice;
  final ValueChanged<double> onPriceChanged;

  const _SmartPricing({
    required this.enabled,
    required this.onToggle,
    required this.basePrice,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI dynamic pricing toggle card with a lime gradient.
        Container(
          padding: const EdgeInsets.all(Spacing.x4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                BrandColors.primary.withValues(alpha: 0.22),
                BrandColors.primary.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(Radii.card),
            border:
                Border.all(color: BrandColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: BrandColors.primary),
              const SizedBox(width: Spacing.x3),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI dynamic pricing',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    SizedBox(height: 2),
                    Text(
                      '+\$284 estimated this month',
                      style: TextStyle(
                        color: BrandColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: BrandColors.primaryFg,
                activeTrackColor: BrandColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.x4),
        // Base daily price slider with low/fair/high markers.
        Container(
          padding: const EdgeInsets.all(Spacing.x4),
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: BrandColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Base daily price',
                      style: TextStyle(color: BrandColors.mutedFg)),
                  const Spacer(),
                  Text(
                    '\$${basePrice.round()}/day',
                    style: const TextStyle(
                      color: BrandColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: BrandColors.primary,
                  inactiveTrackColor: BrandColors.surface2,
                  thumbColor: BrandColors.primary,
                  overlayColor: BrandColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: basePrice.clamp(20, 300),
                  min: 20,
                  max: 300,
                  onChanged: onPriceChanged,
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Low',
                      style: TextStyle(
                          color: BrandColors.mutedFg, fontSize: 11)),
                  Text('Fair',
                      style: TextStyle(
                          color: BrandColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Text('High',
                      style: TextStyle(
                          color: BrandColors.mutedFg, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.x4),
        // Auto-adjust rules.
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.x4, vertical: Spacing.x2),
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: BrandColors.border),
          ),
          child: const Column(
            children: [
              _RuleRow(label: 'Weekend premium', delta: '+15%', up: true),
              _RuleDivider(),
              _RuleRow(label: 'High-demand events', delta: '+25%', up: true),
              _RuleDivider(),
              _RuleRow(label: 'Last-minute', delta: '−10%', up: false),
              _RuleDivider(),
              _RuleRow(label: 'Long trips', delta: '−12%', up: false),
            ],
          ),
        ),
        const SizedBox(height: Spacing.x2),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final String delta;
  final bool up;
  const _RuleRow({required this.label, required this.delta, required this.up});

  @override
  Widget build(BuildContext context) {
    final color = up ? BrandColors.success : BrandColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x3),
      child: Row(
        children: [
          Icon(up ? Icons.trending_up : Icons.trending_down,
              size: 18, color: color),
          const SizedBox(width: Spacing.x3),
          Expanded(child: Text(label)),
          Text(
            delta,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RuleDivider extends StatelessWidget {
  const _RuleDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: BrandColors.border);
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

/// Full-width lime pill primary button (~56 tall, radius 28).
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.primaryFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BrandColors.primaryFg),
              )
            : Text(label),
      ),
    );
  }
}
