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
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateDates();
    
    // Scroll to show today on the right after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }
  
  void _generateDates() {
    final today = DateTime.now();
    _dates = List.generate(_totalDays, (index) {
      return DateTime(today.year, today.month, today.day - (_totalDays - 1 - index));
    });
  }
  
  void _scrollToToday() {
    if (_scrollController.hasClients) {
      // Scroll to the end (today is at the end)
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _isSameDay(date, widget.selectedDate);
          final isToday = _isToday(date);
          
          return GestureDetector(
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
                    ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayLabel(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected 
                          ? Colors.black87 
                          : Colors.white.withOpacity(0.7),
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
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
