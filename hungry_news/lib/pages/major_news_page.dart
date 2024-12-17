import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/utility.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'news_detail_page.dart';

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
  bool isReversed = false;
  final GlobalKey<NewsDetailPageState> newsDetailPageKey =
      GlobalKey<NewsDetailPageState>();

  final ValueNotifier<int> unreadNewsCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    currentDate = getToday();
    fetchNews();
    NewsStateManager.allSavedStatesNotifier.addListener(_onSavedStateUpdated);
    NewsStateManager.allReadStatesNotifier.addListener(_onReadStateUpdated);
  }

  Future<void> refreshPage() async {
    await fetchNews();
    setState(() {}); // Rebuild the page
  }

  @override
  void dispose() {
    unreadNewsCount.dispose();
    NewsStateManager.allSavedStatesNotifier
        .removeListener(_onSavedStateUpdated);
    NewsStateManager.allReadStatesNotifier.removeListener(_onReadStateUpdated);
    super.dispose();
  }

  void _onSavedStateUpdated() {
    setState(() {
      final savedStates = NewsStateManager.allSavedStatesNotifier.value;
      for (var news in newsData) {
        final key = NewsStateManager.generateCompositeKey(
            news['table_name'], news['news_id']);
        if (savedStates.containsKey(key)) {
          news['is_saved'] = savedStates[key];
        }
      }
    });
  }

  void _onReadStateUpdated() {
    setState(() {
      final readStates = NewsStateManager.allReadStatesNotifier.value;
      for (var news in newsData) {
        final key = NewsStateManager.generateCompositeKey(
            news['table_name'], news['news_id']);
        if (readStates.containsKey(key)) {
          news['is_read'] = readStates[key];
        }
      }
    });
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
    String tableName = getWeekTableName(currentDate);
    try {
      final response = await http
          .get(Uri.parse('https://hungrynews-backend.onrender.com/major-news'));
      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);

        // Overwrite is_read and is_saved from persistent storage
        for (var news in fetchedData) {
          int newsId = news['news_id'];
          news['table_name'] = tableName;
          news['is_read'] =
              await NewsStateManager.getIsRead(tableName, newsId) ?? false;
          news['is_saved'] =
              await NewsStateManager.getIsSaved(tableName, newsId) ?? false;
        }

        setState(() {
          newsData = fetchedData
            ..sort((a, b) {
              int comparison = parseNewsDate(b['datetime'])
                  .compareTo(parseNewsDate(a['datetime']));
              return isReversed ? -comparison : comparison;
            });
          isLoading = false;
          NewsStateManager.initializeUnreadCount(newsData);
        });
      } else if (response.statusCode == 503) {
        setState(() {
          isLoading = false;
          errorMessage = "Please wait while I generate this week's database";
        });
      } else {
        throw Exception('Failed to load news');
      }
    } on SocketException {
      setState(() {
        isLoading = false;
        errorMessage =
            "Unable to connect to the server. Please check your internet connection and try again.";
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "An unexpected error occurred. Please try again later.";
      });
    }
  }

  void decrementUnreadNewsCount(String tableName, int impactLevel) {
    NewsStateManager.decrementUnreadCount(tableName, impactLevel);
  }

  String getWeekTableName(DateTime date) {
    String weekStart = DateFormat('ddMMyy').format(
      date.subtract(Duration(days: date.weekday - 1)),
    );
    String weekEnd = DateFormat('ddMMyy').format(
      date.add(Duration(days: 7 - date.weekday)),
    );
    return '$weekStart-$weekEnd';
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
        const SizedBox(height: 100),
        Center(
          child: Text(
            errorMessage,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        )
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
      bool isRead = news['is_read'] == true; // persistent storage value
      DateTime newsDateTime = parseNewsDate(news['datetime']);
      String title = news['title'];
      String url = news['url'];
      String source = news['source'];
      bool isSaved = news['is_saved'] == true;
      int newsId = news['news_id'];
      int impactLevel = news['impact_level'];
      // final isReadGlobal =
      //     NewsStateManager.allReadStatesNotifier.value[news['news_id']] ??
      //         false;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              final updatedData = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsDetailPage(
                    key: newsDetailPageKey,
                    title: title,
                    url: url,
                    source: source,
                    isSaved: isSaved,
                    newsId: newsId,
                    isRead: isRead,
                    originalDatetime: newsDateTime,
                    tableName: news['table_name'],
                    impactLevel: impactLevel,
                    decrementUnreadCount: (tableName, level) =>
                        decrementUnreadNewsCount(tableName, level),
                  ),
                ),
              );
              

              if (updatedData != null) {
                final updatedIsRead = updatedData['is_read'] ?? false;
                final updatedIsSaved = updatedData['is_saved'] ?? false;

                setState(() {
                  // Update the local `newsData` list
                  final index = newsData.indexWhere((n) =>
                      n['news_id'] == newsId &&
                      n['table_name'] == news['table_name']);
                  if (index != -1) {
                    newsData[index]['is_read'] = updatedIsRead;
                    newsData[index]['is_saved'] = updatedIsSaved;
                  }

                  // Sync with global state
                  final compositeKey = NewsStateManager.generateCompositeKey(
                      news['table_name'], newsId);
                  NewsStateManager.allReadStatesNotifier.value = {
                    ...NewsStateManager.allReadStatesNotifier.value,
                    compositeKey: updatedIsRead,
                  };
                });
              }
            },
            child: Container(
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
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
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
        child: RefreshIndicator(
          onRefresh: () async {
            await fetchNews();
            setState(() {
              currentDate = getToday();
            });
          },
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  child: Container(
                    height: 160,
                    color: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.only(
                        top: 40.0, left: 16.0, right: 16.0, bottom: 16.0),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10), // HERE
                            Text(
                              'Major News',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
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
                          key: ValueKey(currentDate),
                          right: 0,
                          child: IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () async {
                              await fetchNews();
                              setState(() {
                                currentDate = getToday();
                              });
                            },
                          ),
                        ),
                        Positioned(
                          right: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isReversed
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.swap_vert,
                                  color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  isReversed = !isReversed;
                                  newsData = newsData.reversed.toList();
                                });
                              },
                            ),
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
