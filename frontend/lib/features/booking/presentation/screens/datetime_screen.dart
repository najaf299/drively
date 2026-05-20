import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/car.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/booking_draft.dart';

/// Pick the pickup/return date range and times for a booking.
class DateTimeScreen extends StatefulWidget {
  final Car car;
  const DateTimeScreen({super.key, required this.car});

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _returnTime = const TimeOfDay(hour: 10, minute: 0);

  int get _days {
    if (_rangeStart == null || _rangeEnd == null) return 0;
    final d = _rangeEnd!.difference(_rangeStart!).inDays;
    return d < 1 ? 1 : d;
  }

  bool get _valid => _rangeStart != null && _rangeEnd != null;

  DateTime _combine(DateTime day, TimeOfDay time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  Future<void> _pickTime(bool pickup) async {
    final result = await showTimePicker(
      context: context,
      initialTime: pickup ? _pickupTime : _returnTime,
    );
    if (result != null) {
      setState(() => pickup ? _pickupTime = result : _returnTime = result);
    }
  }

  void _confirm() {
    if (!_valid) return;
    var pickupAt = _combine(_rangeStart!, _pickupTime);
    final returnAt = _combine(_rangeEnd!, _returnTime);
    // Backend requires pickup_at strictly in the future.
    if (!pickupAt.isAfter(DateTime.now())) {
      pickupAt = DateTime.now().add(const Duration(hours: 1));
    }
    context.push(
      '/booking',
      extra: BookingDraft(
        car: widget.car,
        pickupAt: pickupAt,
        returnAt: returnAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Select dates')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.x4),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.x2),
                      child: TableCalendar(
                        firstDay: today,
                        lastDay: today.add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        rangeStartDay: _rangeStart,
                        rangeEndDay: _rangeEnd,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        calendarStyle: const CalendarStyle(
                          rangeHighlightColor: BrandColors.surface2,
                          rangeStartDecoration: BoxDecoration(
                              color: BrandColors.primary,
                              shape: BoxShape.circle),
                          rangeEndDecoration: BoxDecoration(
                              color: BrandColors.primary,
                              shape: BoxShape.circle),
                          rangeStartTextStyle:
                              TextStyle(color: BrandColors.primaryFg),
                          rangeEndTextStyle:
                              TextStyle(color: BrandColors.primaryFg),
                          todayDecoration: BoxDecoration(
                              color: BrandColors.surface2,
                              shape: BoxShape.circle),
                          withinRangeTextStyle:
                              TextStyle(color: BrandColors.foreground),
                          defaultTextStyle:
                              TextStyle(color: BrandColors.foreground),
                          weekendTextStyle:
                              TextStyle(color: BrandColors.foreground),
                          disabledTextStyle:
                              TextStyle(color: BrandColors.mutedFg),
                        ),
                        onRangeSelected: (start, end, focused) {
                          setState(() {
                            _rangeStart = start;
                            _rangeEnd = end;
                            _focusedDay = focused;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.x4),
                  Row(
                    children: [
                      Expanded(
                        child: _timeTile(
                            'Pickup time', _pickupTime, () => _pickTime(true)),
                      ),
                      const SizedBox(width: Spacing.x3),
                      Expanded(
                        child: _timeTile(
                            'Return time', _returnTime, () => _pickTime(false)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _summaryBar(),
        ],
      ),
    );
  }

  Widget _timeTile(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.x3),
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: BrandColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: BrandColors.mutedFg),
            const SizedBox(width: Spacing.x2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: BrandColors.mutedFg, fontSize: 11)),
                Text(time.format(context),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBar() {
    final subtotal = widget.car.dailyPrice * _days;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(Spacing.x4),
        decoration: const BoxDecoration(
          color: BrandColors.surface,
          border: Border(top: BorderSide(color: BrandColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_valid)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.x3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${Formatters.money(widget.car.dailyPrice)} × '
                      '${Formatters.plural(_days, 'day')}',
                      style: const TextStyle(color: BrandColors.mutedFg),
                    ),
                    Text(Formatters.money(subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _valid ? _confirm : null,
                child: Text(_valid ? 'Confirm dates' : 'Select your dates'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
