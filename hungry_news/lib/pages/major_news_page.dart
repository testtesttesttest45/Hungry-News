import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MajorNewsPage extends StatelessWidget {
  final int? currentDay;

  const MajorNewsPage({super.key, this.currentDay});

  DateTime getToday() {
    DateTime now = DateTime.now();
    return currentDay != null
        ? DateTime(now.year, now.month, currentDay!)
        : now;
  }

  String getFormattedDate() {
    DateTime now = getToday();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // find out the first Sunday and Monday of the month
    int firstDayWeekday = firstDayOfMonth.weekday;
    DateTime firstSunday = firstDayWeekday == 7
        ? firstDayOfMonth
        : firstDayOfMonth.add(Duration(days: 7 - firstDayWeekday));
    DateTime firstMonday = firstDayWeekday == 1
        ? firstDayOfMonth
        : firstDayOfMonth.add(Duration(days: (8 - firstDayWeekday) % 7));

    // check week boundaries
    DateTime weekStart, weekEnd;
    if (now.isBefore(firstMonday)) {
        // handle the first week when the month doesn't start on a Monday
        weekStart = firstDayOfMonth;
        weekEnd = firstSunday;
    } else {
        // start weeks from Monday after the first Sunday
        int daysSinceFirstMonday = now.difference(firstMonday).inDays;
        int weeksSinceFirstMonday = daysSinceFirstMonday ~/ 7;
        weekStart = firstMonday.add(Duration(days: weeksSinceFirstMonday * 7));
        weekEnd = weekStart.add(const Duration(days: 6));
    }

    // Ensure the weekEnd does not exceed the month's last day
    if (weekEnd.isAfter(lastDayOfMonth)) {
        weekEnd = lastDayOfMonth;
    }

    // find week nubmer
    int weekNumber = ((weekStart.difference(firstDayOfMonth).inDays) / 7).ceil() + 1;
    int totalWeeks = ((lastDayOfMonth.day + (firstDayWeekday - 1)) / 7).ceil();

    String formattedDate = DateFormat('dd MMM yyyy, EEEE, HHmm\'HRS\'').format(now);
    String weekRange = '${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';

    return '$formattedDate\nDisplaying news from Week $weekNumber of $totalWeeks\n($weekRange)';
}

  List<Widget> generateNewsItems() {
  DateTime today = getToday();
  List<Widget> newsItems = [];
  for (int i = 0; i < 10; i++) {
    DateTime newsDate = today.subtract(Duration(days: i));
    String formattedDate = DateFormat('dd MMM yyyy').format(newsDate);

    newsItems.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and tick
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Major News ${i + 1}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (i < 3)
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: Colors.grey[400]),
        ],
      ),
    );
  }
  return newsItems;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Major News'),
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              //  for refresh functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest Updates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                getFormattedDate(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Divider(color: Colors.grey[400]),
              const SizedBox(height: 20),
              ...generateNewsItems(),
            ],
          ),
        ),
      ),
    );
  }
}
