// ============================================================
// TIME PICKER SHEET — GetWork App
// Scroll-wheel time picker (hour | minute | AM/PM)
// inspired by slot-machine style UI
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

  static const double _itemHeight = 52;
  static const int _visibleItems = 5;

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
      // Format: "08:30 AM"
      final parts = t.trim().split(' ');
      if (parts.length == 2) {
        final hm = parts[0].split(':');
        _selectedHour = int.parse(hm[0]);
        _selectedMinute = int.parse(hm[1]);
        _selectedPeriod = parts[1].toUpperCase() == 'PM' ? 1 : 0;
        // Clamp hour to 1-12
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

  Widget _buildColumn({
    required List<dynamic> items,
    required FixedExtentScrollController controller,
    required void Function(int) onChanged,
    required String Function(dynamic) label,
  }) {
    return SizedBox(
      width: 80,
      height: _itemHeight * _visibleItems,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selected highlight
          Positioned(
            top: _itemHeight * (_visibleItems ~/ 2),
            child: Container(
              width: 72,
              height: _itemHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          // Fade top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _itemHeight * 1.8,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fade bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _itemHeight * 1.8,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Wheel
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _itemHeight,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildLoopingListDelegate(
              children: items.map((item) {
                final idx = items.indexOf(item);
                return Center(
                  child: Text(
                    label(item),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: idx == controller.initialItem
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Time',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Live preview
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_hourCtrl, _minCtrl, _periodCtrl]),
                  builder: (_, __) {
                    return Container(
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
                    );
                  },
                ),
              ],
            ),
          ),

          // Wheel columns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour
                _WheelColumn(
                  items: _hours.map((h) => h.toString().padLeft(2, '0')).toList(),
                  controller: _hourCtrl,
                  onChanged: (i) => setState(
                      () => _selectedHour = _hours[i % _hours.length]),
                ),
                const SizedBox(width: 4),
                const Text(':',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                // Minute
                _WheelColumn(
                  items:
                      _minutes.map((m) => m.toString().padLeft(2, '0')).toList(),
                  controller: _minCtrl,
                  onChanged: (i) => setState(
                      () => _selectedMinute = _minutes[i % _minutes.length]),
                ),
                const SizedBox(width: 16),
                // AM/PM
                _WheelColumn(
                  items: _periods,
                  controller: _periodCtrl,
                  onChanged: (i) =>
                      setState(() => _selectedPeriod = i % _periods.length),
                  itemWidth: 72,
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
                    colors: [Color(0xFF1F2933), Color(0xFF0F172A)],
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
                  child: const Text('Confirm'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wheel Column widget ─────────────────────────────────────────
class _WheelColumn extends StatelessWidget {
  final List<String> items;
  final FixedExtentScrollController controller;
  final void Function(int) onChanged;
  final double itemWidth;

  static const double _itemHeight = 52.0;
  static const int _visibleItems = 5;

  const _WheelColumn({
    required this.items,
    required this.controller,
    required this.onChanged,
    this.itemWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: itemWidth,
      height: _itemHeight * _visibleItems,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selected highlight bar
          Center(
            child: Container(
              width: itemWidth - 8,
              height: _itemHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          // Fade top overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _itemHeight * 1.5,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fade bottom overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _itemHeight * 1.5,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // The wheel
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _itemHeight,
            diameterRatio: 2.0,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildLoopingListDelegate(
              children: List.generate(items.length, (i) {
                return Center(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (_, __) {
                      final selected = controller.hasClients
                          ? controller.selectedItem % items.length == i
                          : controller.initialItem == i;
                      return Text(
                        items[i],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: selected ? 22 : 18,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
