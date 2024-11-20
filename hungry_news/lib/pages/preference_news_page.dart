import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PreferenceNewsPage extends StatefulWidget {
  const PreferenceNewsPage({super.key});

  @override
  State<PreferenceNewsPage> createState() => _PreferenceNewsPageState();
}

class _PreferenceNewsPageState extends State<PreferenceNewsPage> {
  late DateTime currentDate;
  late DateTime referenceDate;
  List<String> topics = ["Space", "War"];

  @override
  void initState() {
    super.initState();
    referenceDate =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

    currentDate = referenceDate;
  }

  DateTime getStartDate() {
    DateTime now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1)); // mondays
  }

  String getFormattedDate() {
    DateTime weekStart = currentDate;
    DateTime weekEnd = weekStart.add(const Duration(days: 6)); // sundays

    return '${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
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
                            'Preference News',
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
                                'News from: ${getFormattedDate()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 16,
                      child: IconButton(
                        icon: Icon(Icons.add,
                            color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () => _showAddTopicDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Topics:',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: topics
                              .map(
                                (topic) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    topic,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Preference news articles go here',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeeksDialog(BuildContext context) {
    referenceDate =
        referenceDate.subtract(Duration(days: referenceDate.weekday - 1));

    DateTime selectedWeekStart =
        currentDate.subtract(Duration(days: currentDate.weekday - 1));

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
              reverse: false,
              itemBuilder: (context, index) {
                DateTime startOfWeek =
                    referenceDate.subtract(Duration(days: 7 * index));
                DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

                bool isSelectedWeek =
                    startOfWeek.isAtSameMomentAs(selectedWeekStart);

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

  void _showAddTopicDialog(BuildContext context) {
    final TextEditingController topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Topic'),
          content: TextField(
            controller: topicController,
            decoration: const InputDecoration(hintText: 'Enter topic name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (topicController.text.isNotEmpty) {
                  setState(() {
                    topics.add(topicController.text);
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Add',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
