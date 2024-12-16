import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'news_detail_page.dart';
import '../utils/utility.dart';

class SearchNewsPage extends StatefulWidget {
  const SearchNewsPage({super.key});

  @override
  SearchNewsPageState createState() => SearchNewsPageState();
}

class SearchNewsPageState extends State<SearchNewsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String errorMessage = '';
  bool hasSearched = false;
  static bool isReversed = false;
  final GlobalKey<NewsDetailPageState> newsDetailPageKey =
      GlobalKey<NewsDetailPageState>();

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      searchResults = [];
      hasSearched = true;
    });

    String query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Please enter a search term.";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://hungrynews-backend.onrender.com/search-news?query=$query'),
      );

      if (response.statusCode == 200) {
        List<dynamic> results = jsonDecode(response.body);

        setState(() {
          searchResults = results.map((news) {
            news['datetime'] =
                parseNewsDate(news['datetime']).toIso8601String();
            return news;
          }).toList();

          searchResults.sort((a, b) {
            DateTime dateA = DateTime.parse(a['datetime']);
            DateTime dateB = DateTime.parse(b['datetime']);
            return isReversed
                ? dateA.compareTo(dateB)
                : dateB.compareTo(dateA); // most recent first
          });

          isLoading = false;

          if (searchResults.isEmpty) {
            errorMessage = "No results found for \"$query\".";
          }
        });
      } else {
        throw Exception("Failed to fetch search results");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "An error occurred while searching. Please try again.";
      });
    }
  }

  DateTime parseNewsDate(String dateString) {
    try {
      DateFormat format = DateFormat('EEE, dd MMM yyyy HH:mm:ss \'GMT\'');
      return format.parse(dateString, true).toUtc();
    } catch (e) {
      return DateTime.now();
    }
  }

  void _reverseSearchResults() {
    setState(() {
      isReversed = !isReversed;
      searchResults = searchResults.reversed.toList();
    });
  }

  void _updateSearchResults() {
    setState(() {
      for (var news in searchResults) {
        final compositeKey = NewsStateManager.generateCompositeKey(
            news['table_name'], news['news_id']);
        news['is_saved'] =
            NewsStateManager.allSavedStatesNotifier.value[compositeKey] ??
                false;
      }
    });
  }

  List<Widget> _generateSearchResultItems() {
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

    if (searchResults.isEmpty && hasSearched) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              "No results found.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ];
    }

    if (searchResults.isEmpty && !hasSearched) {
      return [];
    }

    List<Widget> resultWidgets = [
      Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
        child: Center(
          child: Text(
            '${searchResults.length} result${searchResults.length > 1 ? 's' : ''} found',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      const Divider(),
    ];

    resultWidgets.addAll(searchResults.map((news) {
      String title = news['title'];
      DateTime newsDateTime = DateTime.parse(news['datetime']);
      final impactLevel = news['impact_level'];

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
                      title: news['title'],
                      url: news['url'],
                      source: news['source'],
                      isSaved: news['is_saved'] ?? false,
                      newsId: news['news_id'],
                      isRead: news['is_read'] ?? false,
                      originalDatetime: newsDateTime,
                      tableName: news['table_name'],
                      impactLevel: news['impact_level']),
                ),
              );

              if (updatedData != null) {
                final updatedIsSaved = updatedData['is_saved'] ?? false;

                setState(() {
                  // Update the specific news item's `is_saved` state in the searchResults list
                  final index = searchResults.indexWhere((n) =>
                      n['news_id'] == news['news_id'] &&
                      n['table_name'] == news['table_name']);
                  if (index != -1) {
                    searchResults[index]['is_saved'] = updatedIsSaved;
                  }
                });
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 40.0),
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
                          DateFormat('dd MMM yyyy, HH:mm').format(newsDateTime),
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.grey[600]),
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

    return resultWidgets;
  }

  @override
  void initState() {
    super.initState();
    NewsStateManager.allSavedStatesNotifier.addListener(_updateSearchResults);
  }

  @override
  void dispose() {
    NewsStateManager.allSavedStatesNotifier
        .removeListener(_updateSearchResults);
    super.dispose();
  }

  void refreshPage() {
    setState(() {
      _searchController.clear(); // Clear the search bar
      searchResults = []; // Clear search results
      isLoading = false;
      errorMessage = '';
      hasSearched = false;
      isReversed = false; // Reset reversed state
    });
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search News',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          IconButton(
                            onPressed: _reverseSearchResults,
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
                      Text(
                        "Searches up to 3 months old news",
                        style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "What are you looking for?",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => _performSearch(),
                            ),
                          ),
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ],
                    ),
                  ),
                  ..._generateSearchResultItems(),
                ],
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
