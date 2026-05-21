import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/car.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/booking_draft.dart';

/// Date & time picker — spec §6 date & time, §7.13.
///
/// Date range picker: selected day = primary circle, in-range = primary @~20%.
/// Pickup/return time chips pill row.
/// Helper 'Minimum 4 hours · Maximum 30 days'.
/// Confirm = PrimaryButton (FilledButton via theme).
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, Spacing.x2, Spacing.x5, Spacing.x6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calendar card
                      _calendarCard(context, today),
                      const SizedBox(height: Spacing.x4),

                      // Time pickers row
                      Row(
                        children: [
                          Expanded(
                            child: _timeTile(
                                context, 'Pickup time', _pickupTime,
                                () => _pickTime(true)),
                          ),
                          const SizedBox(width: Spacing.x3),
                          Expanded(
                            child: _timeTile(
                                context, 'Return time', _returnTime,
                                () => _pickTime(false)),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.x4),

                      // Helper text — spec §6.
                      Center(
                        child: Text(
                          'Minimum 4 hours  ·  Maximum 30 days',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: BrandColors.mutedFg),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _summaryBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x4, Spacing.x2, Spacing.x5, Spacing.x2),
      child: Row(
        children: [
          _CircleBackButton(onTap: () => context.pop()),
          const SizedBox(width: Spacing.x3),
          Text('Select dates',
              style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }

  Widget _calendarCard(BuildContext context, DateTime today) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: TableCalendar(
        firstDay: today,
        lastDay: today.add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        rangeStartDay: _rangeStart,
        rangeEndDay: _rangeEnd,
        rangeSelectionMode: RangeSelectionMode.toggledOn,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        rowHeight: 46,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: const Icon(Icons.chevron_left_rounded,
              color: BrandColors.foreground),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded,
              color: BrandColors.foreground),
          titleTextStyle: Theme.of(context).textTheme.titleLarge!,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: Theme.of(context)
              .textTheme
              .labelMedium!
              .copyWith(color: BrandColors.mutedFg),
          weekendStyle: Theme.of(context)
              .textTheme
              .labelMedium!
              .copyWith(color: BrandColors.mutedFg),
        ),
        calendarStyle: CalendarStyle(
          // In-range: primary @ ~20%
          rangeHighlightColor:
              BrandColors.primary.withValues(alpha: 0.20),
          // Selected start/end: primary circle.
          rangeStartDecoration: const BoxDecoration(
            color: BrandColors.primary,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: const BoxDecoration(
            color: BrandColors.primary,
            shape: BoxShape.circle,
          ),
          rangeStartTextStyle: const TextStyle(
            color: BrandColors.primaryFg,
            fontWeight: FontWeight.w700,
          ),
          rangeEndTextStyle: const TextStyle(
            color: BrandColors.primaryFg,
            fontWeight: FontWeight.w700,
          ),
          // Today ring
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: BrandColors.primary, width: 1.5),
          ),
          todayTextStyle: const TextStyle(
            color: BrandColors.primary,
            fontWeight: FontWeight.w600,
          ),
          withinRangeTextStyle:
              const TextStyle(color: BrandColors.foreground),
          defaultTextStyle:
              const TextStyle(color: BrandColors.foreground),
          weekendTextStyle:
              const TextStyle(color: BrandColors.foreground),
          outsideTextStyle:
              const TextStyle(color: BrandColors.mutedFg),
          disabledTextStyle: TextStyle(
            color: BrandColors.mutedFg.withValues(alpha: 0.4),
          ),
        ),
        onRangeSelected: (start, end, focused) {
          setState(() {
            _rangeStart = start;
            _rangeEnd = end;
            _focusedDay = focused;
          });
        },
      ),
    );
  }

  /// Pill time tile — spec §7.13 pickup/return time chips.
  Widget _timeTile(
      BuildContext context, String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x4, vertical: Spacing.x3),
        decoration: BoxDecoration(
          color: BrandColors.surface2,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: BrandColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded,
                size: Sizes.iconSm, color: BrandColors.primary),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(time.format(context),
                      style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBar(BuildContext context) {
    final subtotal = widget.car.dailyPrice * _days;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x4),
      decoration: const BoxDecoration(
        color: BrandColors.background,
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: BrandColors.mutedFg),
                  ),
                  Text(
                    Formatters.money(subtotal),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: BrandColors.primary),
                  ),
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
    );
  }
}

/// Circular 40 px back button — surface bg, border.
class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: BrandColors.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: BrandColors.foreground),
        ),
      ),
    );
  }
}
