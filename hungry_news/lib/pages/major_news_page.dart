import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/utils/time_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

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
      final response = await http.get(Uri.parse('https://hungrynews-backend.onrender.com/major-news'));
      if (response.statusCode == 200) {
        setState(() {
          newsData = jsonDecode(response.body)
            ..sort((a, b) {
              int comparison = parseNewsDate(b['datetime'])
                  .compareTo(parseNewsDate(a['datetime']));
              return isReversed ? -comparison : comparison;
            });
          isLoading = false;
        });
      } else if (response.statusCode == 503) {
        setState(() {
          isLoading = false;
          errorMessage = "Please wait while I generate this week's database";
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

    List<Widget> newsWidgets = [
      const SizedBox(height: 30),
    ];

    newsWidgets.addAll(newsData.map((news) {
      bool isRead = news['is_read'] == 1;
      DateTime newsDateTime = parseNewsDate(news['datetime']);
      String title = news['title'];
      String url = news['url'];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsDetailPage(
                    title: title,
                    url: url,
                  ),
                ),
              );
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
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
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
              currentDate = DateTime.now();
            });
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
                          key: ValueKey(currentDate),
                          right: 0,
                          child: IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () async {
                              await fetchNews();
                              setState(() {
                                currentDate = DateTime.now();
                              });
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

class NewsDetailPage extends StatefulWidget {
  final String title;
  final String url;

  const NewsDetailPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  NewsDetailPageState createState() => NewsDetailPageState();
}

class NewsDetailPageState extends State<NewsDetailPage> {
  late Future<String> contentFuture;

  @override
  void initState() {
    super.initState();
    contentFuture =
        fetchArticleContent(widget.url);
  }

  Future<String> fetchArticleContent(String url) async {
    final proxyUrl = 'https://hungrynews-backend.onrender.com/proxy?url=$url'; // use proxy
    try {
      final response = await http.get(Uri.parse(proxyUrl));
      if (response.statusCode == 200) {
        var document = html.parse(response.body);
        var paragraphs = document.getElementsByTagName('p');
        String content = paragraphs.map((p) => p.text).join('\n\n');
        return content.isNotEmpty ? content : "No content available.";
      } else {
        return "Failed to load content. Status code: ${response.statusCode}";
      }
    } catch (e) {
      return "An error occurred while fetching content: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              widget.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          centerTitle: true,
        ),
      ),
      body: FutureBuilder<String>(
        future: contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Text(
                  snapshot.data ?? "No content available.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
