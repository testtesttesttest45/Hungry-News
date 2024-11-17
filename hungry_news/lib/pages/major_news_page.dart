import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MajorNewsPage extends StatefulWidget { // was stateless. need to be stateful to update the date
  final int? currentDay;

  const MajorNewsPage({super.key, this.currentDay});

  @override
  MajorNewsPageState createState() => MajorNewsPageState();
}

class MajorNewsPageState extends State<MajorNewsPage> {
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = getToday();
  }

  DateTime getToday() {
    DateTime now = DateTime.now();
    return widget.currentDay != null
        ? DateTime(now.year, now.month, widget.currentDay!)
        : now;
  }

  String getFormattedDate() {
    DateTime now = currentDate;
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Find the first Monday and calculate week boundaries
    int firstDayWeekday = firstDayOfMonth.weekday;
    DateTime firstMonday = firstDayWeekday == 1
        ? firstDayOfMonth
        : firstDayOfMonth.add(Duration(days: (8 - firstDayWeekday) % 7));
    DateTime weekStart, weekEnd;

    if (now.isBefore(firstMonday)) {
      weekStart = firstDayOfMonth;
      weekEnd = firstMonday.subtract(const Duration(days: 1));
    } else {
      int daysSinceFirstMonday = now.difference(firstMonday).inDays;
      int weeksSinceFirstMonday = daysSinceFirstMonday ~/ 7;
      weekStart = firstMonday.add(Duration(days: weeksSinceFirstMonday * 7));
      weekEnd = weekStart.add(const Duration(days: 6));
    }

    if (weekEnd.isAfter(lastDayOfMonth)) {
      weekEnd = lastDayOfMonth;
    }

    int weekNumber = ((weekStart.difference(firstDayOfMonth).inDays) / 7).ceil() + 1;
    int totalWeeks = ((lastDayOfMonth.day + (firstDayWeekday - 1)) / 7).ceil();

    String formattedDate = DateFormat('dd MMM yyyy, EEEE, HHmm\'HRS\'').format(now);
    String weekRange = '${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';

    return '$formattedDate\nDisplaying news from Week $weekNumber of $totalWeeks\n($weekRange)';
  }

  List<Widget> generateNewsItems() {
    DateTime today = currentDate;
    List<Widget> newsItems = [];
    for (int i = 0; i < 10; i++) {
      DateTime newsDate = today.subtract(Duration(days: i));
      String formattedDate = DateFormat('dd MMM yyyy').format(newsDate);

      newsItems.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 40.0), // Increased horizontal padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add gap on the left and right
              child: Divider(
                color: Colors.grey[400],
                thickness: 1, // Optionally reduce the thickness
              ),
            ),
          ],
        ),
      );
    }
    return newsItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  height: 150, // Adjusted height for the red section
                  color: Colors.red[800],
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Major News',
                            style: TextStyle(
                              fontSize: 24, // Increased font size
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getFormattedDate(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0, // Align to the top-right corner
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              currentDate = DateTime.now(); // Update the date and time
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(generateNewsItems()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 150.0; // Adjusted to match the header height
  @override
  double get minExtent => 150.0;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
