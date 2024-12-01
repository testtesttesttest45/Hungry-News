import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html_unescape/html_unescape.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';

Future<Map<String, dynamic>> fetchArticleContent(String url) async {
  final proxyUrl = 'https://hungrynews-backend.onrender.com/proxy?url=$url';
  final unescape = HtmlUnescape();

  try {
    final response = await http.get(Uri.parse(proxyUrl));

    if (response.statusCode == 200) {
      final utf8Body = utf8.decode(response.bodyBytes);
      final document = html.parse(utf8Body);

      List<Map<String, String>> images = [];
      List<String> paragraphs = [];

      if (url.contains("bbc.com")) {
        paragraphs = document
            .querySelectorAll('div[data-component="text-block"] p')
            .map((p) => unescape.convert(p.text.trim()))
            .toList();

        document
            .querySelectorAll('div[data-component="image-block"] img')
            .forEach((img) {
          final src = img.attributes['src'] ?? '';
          final alt = img.attributes['alt'] ?? 'No caption available';
          if (src.isNotEmpty && src.startsWith('http')) {
            images.add({'src': src, 'alt': unescape.convert(alt)});
          }
        });
      } else if (url.contains("channelnewsasia.com")) {
        paragraphs = document
            .querySelectorAll('div.text p')
            .map((p) => unescape.convert(p.text.trim()))
            .toList();

        document.querySelectorAll('figure img').forEach((img) {
          final src = img.attributes['src'] ?? '';
          final alt = img.attributes['alt'] ?? 'No caption available';
          if (src.isNotEmpty && src.startsWith('http')) {
            images.add({'src': src, 'alt': unescape.convert(alt)});
          }
        });
      } else {
        paragraphs = document
            .getElementsByTagName('p')
            .map((p) => unescape.convert(p.text.trim()))
            .toList();

        document.getElementsByTagName('img').forEach((img) {
          final src = img.attributes['src'] ?? '';
          final alt = img.attributes['alt'] ?? 'No caption available';
          if (src.isNotEmpty && src.startsWith('http')) {
            images.add({'src': src, 'alt': unescape.convert(alt)});
          }
        });
      }

      String content = paragraphs.join('\n\n');
      content = content
          .replaceAll('Â', '')
          .replaceAll(RegExp(r'â'), "'")
          .replaceAll(RegExp(r'â'), "'")
          .replaceAll(RegExp(r'â'), '"')
          .replaceAll(RegExp(r'â'), '"')
          .replaceAll(RegExp(r'[\u00A0\u202F]'), ' ')
          .trim();

      return {
        "content": content.isNotEmpty ? content : "No content available.",
        "images": images, // Return images with captions
      };
    } else {
      return {
        "content":
            "Failed to load content. Status code: ${response.statusCode}",
        "images": []
      };
    }
  } catch (e) {
    return {
      "content": "An error occurred while fetching content: $e",
      "images": []
    };
  }
}

class NewsDetailPage extends StatefulWidget {
  final String title;
  final String url;
  final String source;

  const NewsDetailPage({
    super.key,
    required this.title,
    required this.url,
    required this.source,
  });

  @override
  NewsDetailPageState createState() => NewsDetailPageState();
}

class NewsDetailPageState extends State<NewsDetailPage> {
  late Future<Map<String, dynamic>> contentFuture;
  late PageController _pageController;
  late FlutterTts
      flutterTts; // late means it will be initialized later. we don't need to initialize it here because it's not a constant value
  int currentPage = 0;
  bool isReading = false;
  int? activeParagraphIndex;

  @override
  void initState() {
    super.initState();
    contentFuture = fetchArticleContent(widget.url);
    _pageController = PageController(initialPage: currentPage);
    flutterTts = FlutterTts();


    flutterTts.setErrorHandler((msg) {
      setState(() {
        isReading = false;
        activeParagraphIndex = null; // Reset state on error
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    setState(() {
      isReading = true;
      activeParagraphIndex = null;
    });

    List<String> paragraphs = text.split('\n\n'); // Split text into paragraphs
    flutterTts.awaitSpeakCompletion(true);

    for (int i = 0; i < paragraphs.length; i++) {
      if (!isReading) break; // if user interrupts, stop reading
      setState(() {
        activeParagraphIndex = i; // Highlight current paragraph
      });
      await flutterTts.speak(paragraphs[i]); // Speak the paragraph
    }

    if (isReading) {
      setState(() {
        isReading = false;
        activeParagraphIndex = null; // reset highlighting after completion
      });
    }
  }

  void _stopReading() {
    flutterTts.stop();
    setState(() {
      isReading = false;
      activeParagraphIndex = null; // Reset 
    });
  }

  void _showFullScreenImages(
      List<Map<String, String>> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index]['src']!;
              final caption = images[index]['alt']!;

              return Stack(
                children: [
                  InteractiveViewer(
                    maxScale: 5.0, // zooming up to 5x
                    minScale: 1.0,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain, // image scales proportionally
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 20) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
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
                      const SizedBox(height: 10),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                        textAlign: TextAlign.left,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              child: FutureBuilder<Map<String, dynamic>>(
                future: contentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: ${snapshot.error}"),
                    );
                  } else {
                    final content = snapshot.data?['content'] ?? "No content";
                    final images = snapshot.data?['images'] ?? [];
                    final paragraphs = content.split('\n\n');

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (images.isNotEmpty)
                              SizedBox(
                                height: 250,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    PageView.builder(
                                      controller: _pageController,
                                      itemCount: images.length,
                                      onPageChanged: (index) {
                                        setState(() {
                                          currentPage = index;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final imageUrl = images[index]['src']!;
                                        final caption = images[index]['alt']!;

                                        return Column(
                                          children: [
                                            const SizedBox(height: 20),
                                            GestureDetector(
                                              onTap: () =>
                                                  _showFullScreenImages(
                                                      images, index),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 32.0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              caption,
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    if (currentPage > 0)
                                      Positioned(
                                        left: -5,
                                        top: 50,
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_left,
                                              color: Colors.black),
                                          iconSize: 24,
                                          onPressed: () {
                                            if (currentPage > 0) {
                                              _pageController.previousPage(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    if (currentPage < images.length - 1)
                                      Positioned(
                                        right: -5,
                                        top: 50,
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_right,
                                              color: Colors.black),
                                          iconSize: 24,
                                          onPressed: () {
                                            if (currentPage <
                                                images.length - 1) {
                                              _pageController.nextPage(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: isReading
                                  ? _stopReading
                                  : () => _speak(content),
                              icon: Icon(
                                  isReading ? Icons.stop : Icons.volume_up),
                              label: Text(
                                  isReading ? "Stop reading" : "Read for me"),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: paragraphs.length,
                              itemBuilder: (context, index) {
                                final isActive = index == activeParagraphIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 8.0),
                                  color: isActive
                                      ? Colors.yellow.withOpacity(
                                          0.4) // Highlight current paragraph
                                      : Colors.transparent,
                                  child: Text(
                                    paragraphs[index],
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCreditSection(widget.url, widget.source),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditSection(String url, String source) {
    String displaySource = source.replaceAll('_', ' ').toUpperCase();

    Future<void> openBrowser(String url) async {
      Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: Theme.of(context).dividerColor,
            thickness: 3,
          ),
          Text(
            "End of article",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "I want to credit $displaySource for providing this news.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => openBrowser(url),
            child: Text(
              "Read more here: $url",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ],
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
