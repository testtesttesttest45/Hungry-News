import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'news_detail_page.dart';
import 'major_news_page.dart';
import '../utils/utility.dart';

class SavedNewsPage extends StatefulWidget {
  const SavedNewsPage({super.key});

  @override
  SavedNewsPageState createState() => SavedNewsPageState();
}

class SavedNewsPageState extends State<SavedNewsPage> {
  static bool isReversed = false;

  @override
  void initState() {
    super.initState();
    NewsStateManager.initializeSavedNews().then((_) {
      _sortSavedNews(); // Apply default sorting after loading
    });
    NewsStateManager.allReadStatesNotifier.addListener(_syncReadStates);
  }

  @override
  void dispose() {
    NewsStateManager.allReadStatesNotifier.removeListener(_syncReadStates);
    super.dispose();
  }

  void resetSavedNews() {
    // Clear saved news in persistent storage and refresh UI
    NewsStateManager.savedNewsNotifier.value = [];
    NewsStateManager.allSavedStatesNotifier.value = {};
  }

  void _syncReadStates() {
    setState(() {
      final globalReadStates = NewsStateManager.allReadStatesNotifier.value;

      // Update only the `is_read` field for news in `savedNewsNotifier`
      final updatedSavedNews =
          NewsStateManager.savedNewsNotifier.value.map((news) {
        final isReadGlobal =
            globalReadStates[news['news_id']] ?? news['is_read'];
        return {
          ...news,
          'is_read': isReadGlobal, // Ensure other fields remain untouched
        };
      }).toList();

      NewsStateManager.savedNewsNotifier.value = updatedSavedNews;
    });
  }

  void _sortSavedNews() {
    setState(() {
      // Sort by publishing date in descending order (newest first)
      NewsStateManager.savedNewsNotifier.value.sort((a, b) {
        return DateTime.parse(b['datetime'])
            .compareTo(DateTime.parse(a['datetime']));
      });

      // If isReversed is true, reverse the sorted list for "Oldest First"
      if (isReversed) {
        NewsStateManager.savedNewsNotifier.value =
            NewsStateManager.savedNewsNotifier.value.reversed.toList();
      }
    });
  }

  void _reverseSavedNews() {
    setState(() {
      isReversed = !isReversed;
      _sortSavedNews(); // Reapply sorting with updated `isReversed` flag
    });
  }

  void notifyMajorNewsPage(String tableName, int impactLevel) {
    if (impactLevel == 3 && NewsStateManager.isNewsFromCurrentWeek(tableName)) {
      final majorNewsPageState =
          context.findAncestorStateOfType<MajorNewsPageState>();
      if (majorNewsPageState != null) {
        majorNewsPageState.decrementUnreadNewsCount(tableName, impactLevel);
      }
    }
  }

  List<Widget> generateSavedNewsItems(
      List<Map<String, dynamic>> savedNewsData) {
    if (savedNewsData.isEmpty) {
      return [
        const SizedBox(height: 100),
        Center(
          child: Text(
            "No saved news yet!",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        )
      ];
    }

    List<Widget> savedNewsWidgets = [
      const SizedBox(height: 30), // Initial gap before the first news item
    ];

    savedNewsWidgets.addAll(savedNewsData.map((news) {
      final title = news['title'];
      final datetime = DateTime.parse(news['datetime']);
      final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(datetime);

      final isRead = news['is_read'] ?? false;
      final impactLevel = news['impact_level'];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsDetailPage(
                    title: news['title'],
                    url: news['url'],
                    source: news['source'],
                    isSaved: true,
                    newsId: news['news_id'],
                    isRead: isRead,
                    originalDatetime: datetime,
                    tableName: news['table_name'],
                    impactLevel: news['impact_level'],
                    decrementUnreadCount: (tableName, level) =>
                        notifyMajorNewsPage(tableName, level),
                  ),
                ),
              );

              // Resynchronize saved news state after returning
              setState(() {
                final currentSavedNews =
                    NewsStateManager.savedNewsNotifier.value;

                // Check if the news item is still saved
                final compositeKey = NewsStateManager.generateCompositeKey(
                  news['table_name'],
                  news['news_id'],
                );

                final isStillSaved = NewsStateManager
                        .allSavedStatesNotifier.value[compositeKey] ??
                    false;

                if (isStillSaved) {
                  // Ensure the saved news item exists
                  if (!currentSavedNews.any((n) =>
                      NewsStateManager.generateCompositeKey(
                          n['table_name'], n['news_id']) ==
                      compositeKey)) {
                    NewsStateManager.savedNewsNotifier.value = [
                      ...currentSavedNews,
                      news, // Add back the item if it was somehow removed
                    ];
                  }
                } else {
                  // Remove the news item if it is no longer saved
                  NewsStateManager.savedNewsNotifier.value = currentSavedNews
                      .where((n) =>
                          NewsStateManager.generateCompositeKey(
                              n['table_name'], n['news_id']) !=
                          compositeKey)
                      .toList();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 32.0,
              ),
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
                                color: impactLevel == 3
                                    ? Theme.of(context).colorScheme.secondary
                                    : null, // Apply secondary color if impactLevel is 3
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          formattedDate,
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

    return savedNewsWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await NewsStateManager.initializeSavedNews(); // Refresh saved news
            _sortSavedNews();
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
                        top: 40.0, left: 16.0, right: 16.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saved News',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            IconButton(
                              onPressed: _reverseSavedNews,
                              icon: const Icon(
                                Icons.swap_vert,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isReversed
                              ? "Viewing by Oldest First"
                              : "Viewing by Most Recent First",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: NewsStateManager.savedNewsNotifier,
                builder: (context, savedNewsData, _) {
                  final savedNewsWidgets =
                      generateSavedNewsItems(savedNewsData);

                  return SliverList(
                    delegate: SliverChildListDelegate(
                      savedNewsWidgets,
                    ),
                  );
                },
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
