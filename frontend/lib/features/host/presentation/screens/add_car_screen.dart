import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../data/host_service.dart';
import '../../domain/providers/host_provider.dart';

/// Single-screen car listing form (covers the required `POST /host/cars` fields).
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
      appBar: AppBar(title: const Text('List a car')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.x5),
          children: [
            _section('Basics'),
            _field(_make, 'Make',
                validator: (v) => Validators.required(v, 'Make')),
            _field(_model, 'Model',
                validator: (v) => Validators.required(v, 'Model')),
            Row(children: [
              Expanded(
                  child: _field(_year, 'Year', keyboard: TextInputType.number)),
              const SizedBox(width: Spacing.x3),
              Expanded(
                  child: _field(_plate, 'Plate number',
                      validator: (v) => Validators.required(v, 'Plate'))),
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
                  child:
                      _field(_seats, 'Seats', keyboard: TextInputType.number)),
              const SizedBox(width: Spacing.x3),
              Expanded(
                  child:
                      _field(_doors, 'Doors', keyboard: TextInputType.number)),
            ]),
            _section('Pricing'),
            _field(_price, 'Daily price (\$)',
                keyboard: TextInputType.number,
                validator: (v) => Validators.required(v, 'Price')),
            _section('Location'),
            _field(_address, 'Address',
                validator: (v) => Validators.required(v, 'Address')),
            Row(children: [
              Expanded(
                  child: _field(_city, 'City',
                      validator: (v) => Validators.required(v, 'City'))),
              const SizedBox(width: Spacing.x3),
              SizedBox(
                width: 90,
                child: _field(_country, 'Country',
                    validator: (v) => Validators.required(v, 'Country')),
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
              children: _featureOptions.entries.map((e) {
                final sel = _features.contains(e.key);
                return FilterChip(
                  label: Text(e.value),
                  selected: sel,
                  onSelected: (_) => setState(() =>
                      sel ? _features.remove(e.key) : _features.add(e.key)),
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
            _field(_description, 'Tell renters about your car', maxLines: 4),
            const SizedBox(height: Spacing.x6),
            LoadingButton(
              label: 'List car',
              loading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, Spacing.x4, 0, Spacing.x3),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> options,
      ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.x3),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        dropdownColor: BrandColors.surface,
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}
