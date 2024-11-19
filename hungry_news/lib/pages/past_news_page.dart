import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PastNewsPage extends StatefulWidget {
  final DateTime? testDate; // debug param

  const PastNewsPage({super.key, this.testDate});

  @override
  State<PastNewsPage> createState() => _PastNewsPageState();
}

class _PastNewsPageState extends State<PastNewsPage> {
  late DateTime currentDate;

  late DateTime referenceDate;

  @override
  void initState() {
    super.initState();
    currentDate = getStartDate();
    referenceDate = DateTime
        .now(); // Set this to a fixed reference, such as the current date when the page is first loaded
  }

  DateTime getStartDate() {
    DateTime now;
    if (widget.testDate != null) {
      now = widget.testDate!;
    } else {
      // default
      now = DateTime.now();
    }
    // Find the Monday of the current week then subtract a week
    DateTime startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    return startOfThisWeek.subtract(const Duration(days: 7));
  }

  String getFormattedDate() {
    DateTime weekStart = currentDate;
    DateTime weekEnd = weekStart
        .add(const Duration(days: 6)); // The week runs for 7 days from start

    // search the month's first day and the number of weeks
    // DateTime firstDayOfMonth = DateTime(weekStart.year, weekStart.month, 1);
    // DateTime lastDayOfMonth = DateTime(weekStart.year, weekStart.month + 1, 0);
    // int weekNumber = ((weekStart.difference(firstDayOfMonth).inDays) / 7).ceil() + 1;
    // int totalWeeks = ((lastDayOfMonth.day + (firstDayOfMonth.weekday - 1)) / 7).ceil();

    String weekRange =
        '${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
    return 'Displaying news from $weekRange';
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
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Past News ${i + 1}',
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
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: GestureDetector(
                          onTap: () => _showWeeksDialog(context),
                          child: Text(
                            getFormattedDate(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

  void _showWeeksDialog(BuildContext context) {
  Color textColor = Theme.of(context).textTheme.bodyLarge!.color ?? Colors.black;
  Color backgroundColor = Theme.of(context).cardColor;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Past 10 Weeks'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 10,
            itemBuilder: (context, index) {
              //  use the fixed reference date to calculate the weeks
              DateTime startOfWeek = referenceDate.subtract(
                  Duration(days: 7 * (index + 1) + referenceDate.weekday - 1));
              DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

              bool isSelectedWeek = startOfWeek.isAtSameMomentAs(currentDate.subtract(Duration(days: currentDate.weekday - 1)));

              return ListTile(
                title: Text(
                  '${DateFormat('dd MMM yyyy').format(startOfWeek)} - ${DateFormat('dd MMM yyyy').format(endOfWeek)}',
                  style: TextStyle(
                    color: isSelectedWeek ? Colors.orange[700] : textColor,
                  ),
                ),
                tileColor: isSelectedWeek ? Colors.orange[50] : backgroundColor,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    currentDate = startOfWeek; // Update  selected week
                  });
                },
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      );
    },
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
