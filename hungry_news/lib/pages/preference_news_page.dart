import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PreferenceNewsPage extends StatefulWidget {
  const PreferenceNewsPage({super.key});

  @override
  State<PreferenceNewsPage> createState() => _PreferenceNewsPageState();
}

class NewsItem {
  final String title;
  final String topic;
  final String date;
  final bool isRead;

  NewsItem({
    required this.title,
    required this.topic,
    required this.date,
    this.isRead = false,
  });
}

class _PreferenceNewsPageState extends State<PreferenceNewsPage> {
  late DateTime currentDate;
  late DateTime referenceDate;
  List<String> topics = ["Space", "War"];
  List<String> hiddenTopics = [];

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

  List<NewsItem> generateNewsData() {
    DateTime today = currentDate;
    List<NewsItem> newsData = [];

    for (int i = 0; i < 11; i++) {
      DateTime newsDate = today.subtract(Duration(days: i));
      String formattedDate = DateFormat('dd MMM yyyy').format(newsDate);

      String topic = i % 2 == 0 ? "War" : "Space";
      bool isRead = i < 3;

      newsData.add(
        NewsItem(
          title: '$topic News ${i + 1}',
          topic: topic,
          date: formattedDate,
          isRead: isRead,
        ),
      );
    }
    return newsData;
  }

  List<Widget> generateNewsItems() {
    List<NewsItem> newsData = generateNewsData();
    List<Widget> newsItems = [];

    for (var news in newsData) {
      if (hiddenTopics.contains(news.topic)) continue;

      newsItems.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              news.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                news.topic,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          news.date,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (news.isRead)
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
                thickness: 3,
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
                        vertical: 48.0, horizontal: 16.0),
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
                          children: topics.map((topic) {
                            bool isHidden = hiddenTopics.contains(topic);

                            // number of news with the topic
                            int topicCount = generateNewsData()
                                .where((news) => news.topic == topic)
                                .length;

                            Color pillColor = isHidden
                                ? Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.6)
                                : Theme.of(context).colorScheme.secondary;

                            return GestureDetector(
                              onLongPress: () =>
                                  _showEditTopicDialog(context, topic),
                              onTap: () {
                                setState(() {
                                  if (isHidden) {
                                    hiddenTopics.remove(topic);
                                  } else {
                                    hiddenTopics.add(topic);
                                  }
                                });
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    decoration: BoxDecoration(
                                      color: pillColor,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
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
                                        if (isHidden)
                                          const SizedBox(
                                              width:
                                                  5), // add space before the eye icon
                                        if (isHidden)
                                          Icon(
                                            Icons.visibility_off,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondary,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (topicCount > 0)
                                    Positioned(
                                      top: -5,
                                      right: -5,
                                      child: Container(
                                        padding: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$topicCount',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                  ...generateNewsItems(),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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

  void _showEditTopicDialog(BuildContext context, String topic) {
    final TextEditingController topicController =
        TextEditingController(text: topic);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Topic'),
          content: TextField(
            controller: topicController,
            decoration: const InputDecoration(hintText: 'Enter new topic name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  topics.remove(topic);
                  // Remove all news associated with the topic
                  hiddenTopics.add(topic);
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  int index = topics.indexOf(topic);
                  if (index != -1) topics[index] = topicController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Save',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
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
