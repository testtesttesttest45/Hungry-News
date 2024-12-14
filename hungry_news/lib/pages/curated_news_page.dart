import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'news_detail_page.dart';
import '../utils/utility.dart';

class CuratedNewsPage extends StatefulWidget {
  const CuratedNewsPage({super.key});

  @override
  State<CuratedNewsPage> createState() => CuratedNewsPageState();
}

class CuratedNewsPageState extends State<CuratedNewsPage> {
  late DateTime currentDate;
  late DateTime referenceDate;
  List<dynamic> newsData = [];
  List<String> topics = ["Singapore", "All"];
  List<String> hiddenTopics = [];
  bool isLoading = false;
  bool isReversed = false;
  String errorMessage = '';
  final GlobalKey<NewsDetailPageState> newsDetailPageKey =
      GlobalKey<NewsDetailPageState>();

  @override
  void initState() {
    super.initState();
    referenceDate =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    currentDate = referenceDate;
    fetchNews();
    NewsStateManager.allSavedStatesNotifier.addListener(_onSavedStateUpdated);
    NewsStateManager.allReadStatesNotifier.addListener(_onReadStateUpdated);
  }

  @override
  void dispose() {
    NewsStateManager.allSavedStatesNotifier
        .removeListener(_onSavedStateUpdated);
    NewsStateManager.allReadStatesNotifier.removeListener(_onReadStateUpdated);
    super.dispose();
  }

  Future<void> refreshPage() async {
    await fetchNews();
    setState(() {});
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

  String getFormattedDate() {
    DateTime weekStart = currentDate;
    DateTime weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
  }

  Future<void> fetchNews() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    String tableName = getTableNameForWeek(currentDate);
    try {
      final response = await http.get(Uri.parse(
          'https://hungrynews-backend.onrender.com/curated-news?table_name=$tableName'));

      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);

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
              // return comparison;
              return isReversed ? -comparison : comparison;
            });
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = "No news available for the selected week.";
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch news");
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String getTableNameForWeek(DateTime date) {
    String weekStart = DateFormat('ddMMyy').format(date);
    String weekEnd =
        DateFormat('ddMMyy').format(date.add(const Duration(days: 6)));
    return '$weekStart-$weekEnd';
  }

  DateTime parseNewsDate(String dateString) {
    try {
      DateFormat format = DateFormat('EEE, dd MMM yyyy HH:mm:ss \'GMT\'');
      return format.parse(dateString, true).toUtc();
    } catch (e) {
      return DateTime.now();
    }
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
            style: Theme.of(context).textTheme.bodyMedium,
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

    List<Widget> newsWidgets = [const SizedBox(height: 30)];

    newsWidgets.addAll(newsData.map((news) {
      bool isRead = news['is_read'] == true; // persistent storage value
      DateTime newsDateTime = parseNewsDate(news['datetime']);
      String title = news['title'];
      String url = news['url'];
      String source = news['source'];
      bool isSaved = news['is_saved'] == true;
      int newsId = news['news_id'];
      String topic = source == 'cna_singapore' ? 'Singapore' : 'All';
      bool isHidden = hiddenTopics.contains(topic);

      final isReadGlobal =
          NewsStateManager.allReadStatesNotifier.value[news['news_id']] ??
              false;

      if (isHidden) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsDetailPage(
                    key: newsDetailPageKey,
                    title: title,
                    url: url,
                    source: source,
                    isSaved: isSaved,
                    newsId: newsId,
                    isRead: isReadGlobal,
                    originalDatetime: newsDateTime,
                    tableName: news['table_name'],
                  ),
                ),
              );

              if (newsDetailPageKey.currentState != null) {
                final updatedIsRead = newsDetailPageKey.currentState!.isRead;
                final updatedIsSaved = newsDetailPageKey.currentState!.isSaved;
                setState(() {
                  final index =
                      newsData.indexWhere((n) => n['news_id'] == newsId);
                  if (index != -1) {
                    newsData[index]['is_read'] = updatedIsRead;
                    newsData[index]['is_saved'] = updatedIsSaved;
                  }
                });
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 1.0, horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isRead)
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
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(newsDateTime),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          topic,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              color: Theme.of(context).dividerColor,
              thickness: 1.5,
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
          },
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
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'Curated News',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _showWeeksDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(5),
                                ),
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
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () async {
                              await fetchNews();
                            },
                          ),
                        ),
                        Positioned(
                          right: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isReversed
                                  ? Theme.of(context).colorScheme.secondary
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
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.2),
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
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          Text(
                            'Tap topic to hide',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: topics.map((topic) {
                              bool isHidden = hiddenTopics.contains(topic);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isHidden) {
                                      hiddenTopics.remove(topic);
                                    } else {
                                      hiddenTopics.add(topic);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color: isHidden
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.6)
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondary,
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
                                        Row(
                                          children: [
                                            const SizedBox(width: 5),
                                            Icon(
                                              Icons.visibility_off,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondary,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
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
                      fetchNews();
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
