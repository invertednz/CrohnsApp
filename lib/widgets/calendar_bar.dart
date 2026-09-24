import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarBar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int visibleDays;

  const CalendarBar({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    this.visibleDays = 6,
  }) : super(key: key);

  @override
  State<CalendarBar> createState() => _CalendarBarState();
}

class _CalendarBarState extends State<CalendarBar> {
  late ScrollController _scrollController;
  late List<DateTime> _dates;
  final int _totalDays = 60; // How many days back we can scroll

  // Day tile width (56) plus its horizontal margins (2 x 4).
  static const double _itemExtent = 64;
  static const double _listPadding = 8;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateDates();

    // Show the selected day (today by default, which is on the right).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(animate: true);
    });
  }

  @override
  void didUpdateWidget(CalendarBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected(animate: true);
      });
    }
  }

  void _generateDates() {
    final today = DateTime.now();
    _dates = List.generate(_totalDays, (index) {
      return DateTime(today.year, today.month, today.day - (_totalDays - 1 - index));
    });
  }

  /// Scrolls just enough to bring the selected day into view.
  void _scrollToSelected({required bool animate}) {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final index = _dates.indexWhere((d) => _isSameDay(d, widget.selectedDate));
    final start = index < 0 ? position.maxScrollExtent : _listPadding + index * _itemExtent;
    final end = start + _itemExtent;
    double target = position.pixels;
    if (index < 0 || end > position.pixels + position.viewportDimension) {
      target = end - position.viewportDimension + _listPadding;
    } else if (start < position.pixels) {
      target = start - _listPadding;
    }
    target = target.clamp(0.0, position.maxScrollExtent);
    if (target == position.pixels) return;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  String _getDayLabel(DateTime date) {
    if (_isToday(date)) return 'Today';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_isSameDay(date, yesterday)) return 'Yesterday';
    return DateFormat('EEE').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _listPadding, vertical: 8),
        itemCount: _dates.length,
        itemExtent: _itemExtent,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _isSameDay(date, widget.selectedDate);
          final isToday = _isToday(date);

          // The day's texts merge into one button ("Today 24 Sep"); selected
          // is exposed to assistive technology (aria-current on web).
          return Semantics(
            button: true,
            selected: isSelected,
            child: GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1)
                    : null,
              ),
              // Scale down rather than overflow on narrow tiles or large fonts.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getDayLabel(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.black87
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.black54
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}
