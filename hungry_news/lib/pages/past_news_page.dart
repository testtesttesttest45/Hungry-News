import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PastNewsPage extends StatefulWidget {
  final int? currentDay;  // debug param
  const PastNewsPage({super.key, this.currentDay});

  @override
  State<PastNewsPage> createState() => _PastNewsPageState();
}

class _PastNewsPageState extends State<PastNewsPage> {
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = getStartDate();
  }

  DateTime getStartDate() {
    DateTime now;
    if (widget.currentDay != null) {
      now = DateTime(DateTime.now().year, DateTime.now().month, widget.currentDay!);
    } else {
      now = DateTime.now();
    }
    // find the monday of the week for "now" and then subtracts a week to get the previous week
    DateTime startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    return startOfThisWeek.subtract(const Duration(days: 7));
  }

  String getFormattedDate() {
    DateTime weekStart = currentDate;
    DateTime weekEnd = weekStart.add(const Duration(days: 6)); // The week runs for 7 days from start

    // search the month's first day and the number of weeks
    DateTime firstDayOfMonth = DateTime(weekStart.year, weekStart.month, 1);
    DateTime lastDayOfMonth = DateTime(weekStart.year, weekStart.month + 1, 0);
    int weekNumber = ((weekStart.difference(firstDayOfMonth).inDays) / 7).ceil() + 1;
    int totalWeeks = ((lastDayOfMonth.day + (firstDayOfMonth.weekday - 1)) / 7).ceil();

    String weekRange = '${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
    return 'Displaying news from Week $weekNumber of $totalWeeks\n($weekRange)';
  }

  List<Widget> generatePastNewsItems() {
    // start from todays date and generate recent dates
    DateTime today = DateTime.now();
    List<Widget> savedNewsItems = [
      const SizedBox(height: 30),
    ];
    
    for (int i = 0; i < 4; i++) {
      DateTime newsDate = today.subtract(Duration(days: i));
      String formattedDate = DateFormat('dd MMM yyyy').format(newsDate);

      savedNewsItems.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Past News ${i + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                color: Colors.grey[400],
                thickness: 1,
              ),
            ),
          ],
        ),
      );
    }
    return savedNewsItems;
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
                  height: 160,
                  color: Colors.red[800],
                  padding: const EdgeInsets.only(
                    top: 30.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Past News',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 30),
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
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(generatePastNewsItems()),
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
  double get maxExtent => 160.0;
  @override
  double get minExtent => 160.0;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
