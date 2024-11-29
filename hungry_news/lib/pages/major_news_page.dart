import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/utils/time_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

DateTime parseNewsDate(String dateString) {
  // example: Thu, 28 Nov 2024 11:19:09 GMT
  DateFormat format = DateFormat('EEE, dd MMM yyyy HH:mm:ss \'GMT\'');
  try {
    DateTime dateTime = format.parse(dateString, true).toUtc();
    return dateTime;
  } catch (e) {
    return DateTime.now(); // return current date if parsing fails
  }
}

class MajorNewsPage extends StatefulWidget {
  final int? currentDay;
  final DateTime? testDate;

  const MajorNewsPage({super.key, this.currentDay, this.testDate});

  @override
  MajorNewsPageState createState() => MajorNewsPageState();
}

class MajorNewsPageState extends State<MajorNewsPage> {
  late DateTime currentDate;
  List<dynamic> newsData = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    currentDate = getToday();
    fetchNews();
  }

  DateTime getToday() {
    if (widget.testDate != null) {
      return widget.testDate!;
    } else if (widget.currentDay != null) {
      DateTime sgNow = TimeHelper.currentTime;
      return DateTime(sgNow.year, sgNow.month, widget.currentDay!);
    } else {
      return TimeHelper.currentTime;
    }
  }

  Future<void> fetchNews() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await http
          .get(Uri.parse('https://hungrynews-backend.onrender.com/news'));
      if (response.statusCode == 200) {
        setState(() {
          newsData = jsonDecode(response.body)
            ..sort((a, b) => parseNewsDate(b['datetime'])
                .compareTo(parseNewsDate(a['datetime'])));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString(); // Store the error message
      });
    }
  }

  String getFormattedDate() {
    DateTime now = currentDate;
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
    DateTime weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat('dd MMM yyyy, EEEE, HHmm\'HRS\'').format(now)}\nDisplaying news from ${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
  }

  List<Widget> generateNewsItems() {
    if (isLoading) {
      return [const Center(child: CircularProgressIndicator())];
    }
    if (errorMessage.isNotEmpty) {
      return [
        Center(child: Text(errorMessage))
      ];
    }

    if (newsData.isEmpty) {
      return [
        const SizedBox(height: 100),
        Center(
          child: Text(
            "No news yet! Stay tuned!",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        )
      ];
    }
    List<Widget> newsWidgets = [
      const SizedBox(height: 30),
    ];

    newsWidgets.addAll(newsData.map((news) {
      bool isRead = news['is_read'] == 1;
      DateTime newsDateTime = parseNewsDate(news['datetime']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news['title'], // Display news title from backend
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(newsDateTime),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isRead)
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white, size: 16),
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
      );
    }).toList());

    return newsWidgets;
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
                      top: 40.0, left: 16.0, right: 16.0, bottom: 16.0),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Major News',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            getFormattedDate(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        key: ValueKey(
                            currentDate),
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () async {
                            await fetchNews();
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
            isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate(
                      generateNewsItems(),
                    ),
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
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 160.0;
  @override
  double get minExtent => 160.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
