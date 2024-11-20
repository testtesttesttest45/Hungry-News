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
    // point referenceDate to the start of the current week
    referenceDate =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    // point currentDate to the start of the previous week
    currentDate = referenceDate.subtract(const Duration(days: 7));
  }

  String getFormattedDate() {
    DateTime weekStart = currentDate;
    DateTime weekEnd = weekStart.add(const Duration(days: 6));
    return 'News from: ${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
  }

  List<Widget> generatePastNewsItems() {
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
                color: Theme.of(context).dividerColor,
                thickness: 1,
              ),
            ),
          ],
        ),
      );
    }
    return savedNewsItems;
  }

  void _showWeeksDialog(BuildContext context) {
    TextStyle? defaultTextStyle = Theme.of(context).textTheme.bodyLarge;
    TextStyle? highlightTextStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            );

    Color defaultBackgroundColor = Theme.of(context).colorScheme.surface;
    Color highlightBackgroundColor = Theme.of(context).colorScheme.secondary;

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
              reverse: true,
              itemBuilder: (context, index) {
                DateTime startOfWeek =
                    referenceDate.subtract(Duration(days: 7 * (10 - index)));
                DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

                // checj if the week is selected
                bool isSelectedWeek = startOfWeek.isAtSameMomentAs(currentDate);

                return ListTile(
                  tileColor: isSelectedWeek
                      ? highlightBackgroundColor
                      : defaultBackgroundColor,
                  title: Text(
                    '${DateFormat('dd MMM yyyy').format(startOfWeek)} - ${DateFormat('dd MMM yyyy').format(endOfWeek)}',
                    style:
                        isSelectedWeek ? highlightTextStyle : defaultTextStyle,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      currentDate = startOfWeek;
                    });
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
          ],
        );
      },
    );
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
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  padding: const EdgeInsets.only(
                    top: 40.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Past News',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: GestureDetector(
                          onTap: () => _showWeeksDialog(context),
                          child: Text(
                            getFormattedDate(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
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
