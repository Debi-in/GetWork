// ============================================================
// TIME PICKER SHEET — GetWork App
// Scroll-wheel time picker (hour | minute | AM/PM)
// Fixed initial visibility & non-looping AM/PM
// ============================================================

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TimePickerSheet extends StatefulWidget {
  final String initialTime; // e.g. "08:30 AM"

  const TimePickerSheet({super.key, required this.initialTime});

  static Future<String?> show(BuildContext context, String initial) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimePickerSheet(initialTime: initial),
    );
  }

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  static const _hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  static const _minutes = [
    0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55
  ];
  static const _periods = ['AM', 'PM'];

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;
  late FixedExtentScrollController _periodCtrl;

  int _selectedHour = 8;
  int _selectedMinute = 0;
  int _selectedPeriod = 0; // 0=AM, 1=PM

  static const double _itemHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _parseInitial(widget.initialTime);
    _hourCtrl = FixedExtentScrollController(
        initialItem: _hours.indexOf(_selectedHour));
    _minCtrl = FixedExtentScrollController(
        initialItem: _minutes.indexOf(_selectedMinute));
    _periodCtrl =
        FixedExtentScrollController(initialItem: _selectedPeriod);
  }

  void _parseInitial(String t) {
    try {
      final parts = t.trim().split(' ');
      if (parts.length == 2) {
        final hm = parts[0].split(':');
        _selectedHour = int.parse(hm[0]);
        _selectedMinute = int.parse(hm[1]);
        _selectedPeriod = parts[1].toUpperCase() == 'PM' ? 1 : 0;
        if (_selectedHour == 0) _selectedHour = 12;
        if (!_hours.contains(_selectedHour)) _selectedHour = 8;
        if (!_minutes.contains(_selectedMinute)) _selectedMinute = 0;
      }
    } catch (_) {
      _selectedHour = 8;
      _selectedMinute = 0;
      _selectedPeriod = 0;
    }
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  String _formatResult() {
    final h = _selectedHour.toString().padLeft(2, '0');
    final m = _selectedMinute.toString().padLeft(2, '0');
    final p = _periods[_selectedPeriod];
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with Live Preview
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Shift Time',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatResult(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Wheel Columns
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Highlight Bar in center
                Container(
                  height: _itemHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hour Wheel (Looping)
                    _WheelColumn(
                      controller: _hourCtrl,
                      itemCount: _hours.length,
                      isLooping: true,
                      onChanged: (i) => setState(() =>
                          _selectedHour = _hours[i % _hours.length]),
                      builder: (i) => Text(
                        _hours[i % _hours.length].toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: _selectedHour == _hours[i % _hours.length] ? 22 : 16,
                          fontWeight: _selectedHour == _hours[i % _hours.length]
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: _selectedHour == _hours[i % _hours.length]
                              ? const Color(0xFF0F766E)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const Text(
                      ':',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // Minute Wheel (Looping)
                    _WheelColumn(
                      controller: _minCtrl,
                      itemCount: _minutes.length,
                      isLooping: true,
                      onChanged: (i) => setState(() =>
                          _selectedMinute = _minutes[i % _minutes.length]),
                      builder: (i) => Text(
                        _minutes[i % _minutes.length].toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: _selectedMinute == _minutes[i % _minutes.length] ? 22 : 16,
                          fontWeight: _selectedMinute == _minutes[i % _minutes.length]
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: _selectedMinute == _minutes[i % _minutes.length]
                              ? const Color(0xFF0F766E)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // AM/PM Wheel (Non-looping 2 items)
                    _WheelColumn(
                      controller: _periodCtrl,
                      itemCount: _periods.length,
                      isLooping: false,
                      onChanged: (i) => setState(() => _selectedPeriod = i),
                      builder: (i) => Text(
                        _periods[i],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: _selectedPeriod == i ? 22 : 16,
                          fontWeight: _selectedPeriod == i
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: _selectedPeriod == i
                              ? const Color(0xFF0F766E)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_formatResult()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Confirm Time'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final bool isLooping;
  final void Function(int) onChanged;
  final Widget Function(int) builder;

  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.isLooping,
    required this.onChanged,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        perspective: 0.003,
        diameterRatio: 1.8,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: isLooping
            ? ListWheelChildLoopingListDelegate(
                children: List.generate(
                  itemCount,
                  (index) => Center(child: builder(index)),
                ),
              )
            : ListWheelChildListDelegate(
                children: List.generate(
                  itemCount,
                  (index) => Center(child: builder(index)),
                ),
              ),
      ),
    );
  }
}
