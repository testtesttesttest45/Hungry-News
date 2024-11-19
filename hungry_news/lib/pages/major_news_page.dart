import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MajorNewsPage extends StatefulWidget {
  // was stateless. need to be stateful to update the date
  final int? currentDay;
  final DateTime? testDate;

  const MajorNewsPage({super.key, this.currentDay, this.testDate});

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
    DateTime now;
    if (widget.testDate != null) {
      now = widget.testDate!;
    } else if (widget.currentDay != null) {
      now = DateTime(
          DateTime.now().year, DateTime.now().month, widget.currentDay!);
    } else {
      now = DateTime.now();
    }
    return now;
  }

  String getFormattedDate() {
    DateTime now = currentDate;

    // serch the current week's Monday
    int currentDayWeekday = now.weekday;
    DateTime weekStart = now.subtract(Duration(days: currentDayWeekday - 1));
    DateTime weekEnd = weekStart.add(const Duration(days: 6));

    String formattedDate =
        DateFormat('dd MMM yyyy, EEEE, HHmm\'HRS\'').format(now);
    String weekRange =
        '${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';

    return '$formattedDate\nDisplaying news from $weekRange';
  }

  List<Widget> generateNewsItems() {
  DateTime today = currentDate;
  List<Widget> newsItems = [
    const SizedBox(height: 30),
  ];

  for (int i = 0; i < 10; i++) {
    DateTime newsDate = today.subtract(Duration(days: i));
    String formattedDate = DateFormat('dd MMM yyyy').format(newsDate);

    newsItems.add(
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
                      'Major News ${i + 1}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodyMedium,
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
              color: Theme.of(context).dividerColor,
              thickness: 1,
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
                  height: 160,
                  color: Colors.red[800],
                  padding: const EdgeInsets.only(
                      top: 40.0, left: 16.0, right: 16.0, bottom: 16.0),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Major News',
                            style: TextStyle(
                              fontSize: 24,
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
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              currentDate = DateTime.now();
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
