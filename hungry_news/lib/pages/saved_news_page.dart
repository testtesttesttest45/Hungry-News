import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavedNewsPage extends StatelessWidget {
  const SavedNewsPage({super.key});

  List<Widget> generateSavedNewsItems(BuildContext context) {
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
                        'Saved News ${i + 1}',
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
                    top: 40.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Saved News',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(generateSavedNewsItems(context)),
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
