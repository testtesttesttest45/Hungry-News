import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:html/dom.dart' as dom;

Future<Map<String, dynamic>> fetchArticleContent(
    String url, BuildContext context) async {
  final proxyUrl = 'https://hungrynews-backend.onrender.com/proxy?url=$url';
  final unescape = HtmlUnescape();

  try {
    final response = await http.get(Uri.parse(proxyUrl));

    if (response.statusCode == 200) {
      final utf8Body = utf8.decode(response.bodyBytes);
      final document = html.parse(utf8Body);

      List<Map<String, String>> images = [];
      List<List<InlineSpan>> paragraphs = [];

      void processParagraphs(String selector) {
        document.querySelectorAll(selector).forEach((element) {
          final spans = _extractTextAndLinks(element, unescape, context);
          if (spans.isNotEmpty) {
            paragraphs.add(spans);
          }
        });
      }

      if (url.contains("bbc.com")) {
        processParagraphs('div[data-component="text-block"] p');

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
        // <p> tags inside div.text
        document.querySelectorAll('div.text p').forEach((p) {
          if (p.text.trim().isNotEmpty) {
            final spans = _extractTextAndLinks(p, unescape, context);
            if (spans.isNotEmpty) {
              paragraphs.add(spans);
            }
          }
        });

        // content inside div.text-long
        document.querySelectorAll('div.text-long').forEach((div) {
          final rawParagraphs =
              div.innerHtml.split(RegExp(r'(<br\s*/?>\s*){2,}'));

          for (var rawParagraph in rawParagraphs) {
            final cleanedParagraph = rawParagraph.trim();
            if (cleanedParagraph.isNotEmpty) {
              final wrappedHtml = '<div>$cleanedParagraph</div>';
              final element = dom.Element.html(wrappedHtml);

              final spans = _extractTextAndLinks(element, unescape, context);
              if (spans.isNotEmpty) {
                paragraphs.add(spans);
              }
            }
          }
        });

        // remove empty paragraphs at the end
        while (paragraphs.isNotEmpty &&
            paragraphs.last.every((span) =>
                span is TextSpan && (span.text?.trim().isEmpty ?? true))) {
          paragraphs.removeLast();
        }

        // <img> tags inside figures
        document.querySelectorAll('figure img').forEach((img) {
          final src = img.attributes['src'] ?? '';
          final alt = img.attributes['alt'] ?? 'No caption available';
          if (src.isNotEmpty && src.startsWith('http')) {
            images.add({'src': src, 'alt': unescape.convert(alt)});
          }
        });
      } else {
        processParagraphs('p');

        document.getElementsByTagName('img').forEach((img) {
          final src = img.attributes['src'] ?? '';
          final alt = img.attributes['alt'] ?? 'No caption available';
          if (src.isNotEmpty && src.startsWith('http')) {
            images.add({'src': src, 'alt': unescape.convert(alt)});
          }
        });
      }

      return {
        "content": paragraphs,
        "images": images,
      };
    } else {
      return {
        "content": [
          [
            TextSpan(
              text:
                  "Failed to load content. Status code: ${response.statusCode}",
              style: const TextStyle(color: Colors.red),
            )
          ]
        ],
        "images": []
      };
    }
  } catch (e) {
    return {
      "content": [
        [
          TextSpan(
            text: "An error occurred while fetching content: $e",
            style: const TextStyle(color: Colors.red),
          )
        ]
      ],
      "images": []
    };
  }
}

List<InlineSpan> _extractTextAndLinks(
    dom.Element element, HtmlUnescape unescape, BuildContext context) {
  final spans = <InlineSpan>[];

  for (var i = 0; i < element.nodes.length; i++) {
    final node = element.nodes[i];

    if (node is dom.Text) {
      final cleanText = unescape
          .convert(node.text.trim())
          .replaceAll(RegExp(r'\s*\n\s*'), ' ')
          .replaceAll(RegExp(r'^"\s*|"\s*$'), '"')
          .replaceAll(
              RegExp(r'(\s*<br>\s*)+'), '\n'); // Convert <br> to newlines

      if (cleanText.isNotEmpty) {
        spans.add(TextSpan(text: cleanText));
      }
    } else if (node is dom.Element && node.localName == 'a') {
      final link = node.attributes['href'] ?? '';
      final linkText = unescape.convert(node.text.trim());

      if (linkText.isNotEmpty) {
        spans.add(
          TextSpan(
            text: linkText,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final theme = Theme.of(context);

                launchUrl(
                  Uri.parse(link),
                  customTabsOptions: CustomTabsOptions(
                    colorSchemes: CustomTabsColorSchemes.defaults(
                      toolbarColor: theme.colorScheme.surface,
                    ),
                    shareState: CustomTabsShareState.on,
                    urlBarHidingEnabled: true,
                    showTitle: true,
                    closeButton: CustomTabsCloseButton(
                      icon: CustomTabsCloseButtonIcons.back,
                    ),
                  ),
                );
              },
          ),
        );
      }
    }

    if (i < element.nodes.length - 1) {
      final nextNode = element.nodes[i + 1];
      final isPunctuation = nextNode is dom.Text &&
          nextNode.text.trim().startsWith(RegExp(r'[.,;?!]'));
      final isBreak = nextNode is dom.Element && nextNode.localName == 'br';

      if (!isPunctuation && !isBreak) {
        spans.add(const TextSpan(text: ' '));
      }
    }
  }

  return spans;
}

class NewsDetailPage extends StatefulWidget {
  final String title;
  final String url;
  final String source;
  final bool isSaved;
  final int newsId;
  final bool isRead;

  const NewsDetailPage({
    super.key,
    required this.title,
    required this.url,
    required this.source,
    required this.isSaved,
    required this.newsId,
    required this.isRead,
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
  bool isSummarized = false;
  bool isSaved = false;
  int? activeParagraphIndex;
  bool isRead = false;

  List<List<InlineSpan>> originalContent = [];
  List<List<InlineSpan>> summarizedContent = [];

  @override
  void initState() {
    super.initState();
    contentFuture = fetchArticleContent(widget.url, context);
    _pageController = PageController(initialPage: currentPage);
    flutterTts = FlutterTts();

    isSaved = widget.isSaved;
    isRead = widget.isRead;

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

  List<String> splitParagraphs(String text) {
    return text
        .split(RegExp(r'\n\n|(?<=[.!?])\s+(?=")|(?<=[.!?])\s+(?=\w)'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
  }

  Future<void> _speak(String text) async {
    setState(() {
      isReading = true;
      activeParagraphIndex = null;
    });

    List<String> paragraphs = splitParagraphs(text);
    flutterTts.awaitSpeakCompletion(true);

    flutterTts.setProgressHandler(
        (String currentText, int start, int end, String word) {
      if (!mounted) return;
      for (int i = 0; i < paragraphs.length; i++) {
        if (paragraphs[i].contains(currentText.trim())) {
          setState(() {
            activeParagraphIndex = i;
          });
          break;
        }
      }
    });

    for (int i = 0; i < paragraphs.length; i++) {
      if (!isReading) break;
      if (!mounted) return; // Prevent updates if widget is disposed

      await flutterTts.speak(paragraphs[i].trim());
    }

    if (!mounted) return;
    setState(() {
      isReading = false;
      activeParagraphIndex = null;
    });
  }

  void _stopReading() async {
    await flutterTts.stop();
    if (!mounted) return;
    setState(() {
      isReading = false;
      activeParagraphIndex = null;
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

  Future<List<List<InlineSpan>>> _summarizeContent(
      List<List<InlineSpan>> content) async {
    String plainText = convertSpansToPlainText(content);
    List<String> sentences = plainText.split(RegExp(r'(?<=[.!?])\s+'));

    List<Map<String, dynamic>> scoredSentences = sentences
        .map((sentence) => {"sentence": sentence, "score": sentence.length})
        .toList();

    scoredSentences.sort((a, b) => b['score'].compareTo(a['score']));
    int summaryLength = (sentences.length / 3).ceil();

    List<String> summarySentences = scoredSentences
        .take(summaryLength)
        .map((s) => s['sentence'] as String)
        .toList();

    return summarySentences.map((sentence) {
      return [TextSpan(text: sentence)];
    }).toList();
  }

  Future<void> _toggleBookmark() async {
    final newSavedState = !isSaved;

    setState(() {
      isSaved = newSavedState;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://hungrynews-backend.onrender.com/update-news-save-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'news_id': widget.newsId,
          'is_saved': newSavedState ? 1 : 0, // Convert bool to int
        }),
      );

      if (response.statusCode != 200) {
        // revert the UI state
        setState(() {
          isSaved = !newSavedState;
        });
      }
    } catch (e) {
      // revert the UI state
      setState(() {
        isSaved = !newSavedState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 10) {
          Navigator.pop(context, {
            'is_saved': isSaved,
            'is_read': isRead,
          });
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
                    final images = snapshot.data?['images'] ?? [];
                    originalContent =
                        snapshot.data?['content'] as List<List<InlineSpan>>;

                    final paragraphs =
                        isSummarized ? summarizedContent : originalContent;

                    final bool hasContent = originalContent.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (images.isNotEmpty)
                              SizedBox(
                                width: 400,
                                height: 275,
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
                                                  child: SizedBox(
                                                    height: 180,
                                                    child: Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.contain,
                                                    ),
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
                                        top: 75,
                                        child: IconButton(
                                          icon: Icon(Icons.arrow_left,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface),
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
                                        top: 75,
                                        child: IconButton(
                                          icon: Icon(Icons.arrow_right,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface),
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
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: !hasContent
                                      ? () async {
                                          await flutterTts
                                              .speak("No content available");
                                        }
                                      : isReading
                                          ? _stopReading
                                          : () => _speak(
                                                convertSpansToPlainText(
                                                    isSummarized
                                                        ? summarizedContent
                                                        : originalContent),
                                              ),
                                  icon: Icon(
                                      isReading ? Icons.stop : Icons.volume_up),
                                  label: Text(isReading
                                      ? "Stop reading"
                                      : "Read for me"),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 130,
                                  child: ElevatedButton(
                                    onPressed: !hasContent
                                        ? null
                                        : () async {
                                            if (isSummarized) {
                                              setState(() {
                                                isSummarized = false;
                                              });
                                            } else {
                                              summarizedContent =
                                                  await _summarizeContent(
                                                      originalContent);
                                              setState(() {
                                                isSummarized = true;
                                              });
                                            }
                                          },
                                    child: Text(isSummarized
                                        ? "Original"
                                        : "Summarize"),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  iconSize: 32,
                                  onPressed: _toggleBookmark,
                                  icon: Icon(
                                    isSaved
                                        ? Icons.bookmark_added
                                        : Icons.bookmark_add_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 8.0),
                              child: paragraphs.isNotEmpty
                                  ? SelectableText.rich(
                                      TextSpan(
                                        children: paragraphs
                                            .asMap()
                                            .entries
                                            .expand((entry) {
                                          final int index =
                                              entry.key; // Paragraph index
                                          final List<InlineSpan> spans = entry
                                              .value; // Spans for the paragraph
                                          final bool isActive = index ==
                                              activeParagraphIndex; // Check if active

                                          // Apply background color only to active paragraphs
                                          return [
                                            TextSpan(
                                              children: spans,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    backgroundColor: isActive
                                                        ? Colors.yellow.withOpacity(
                                                            0.4) // Highlight active paragraph
                                                        : Colors.transparent,
                                                  ),
                                            ),
                                            const TextSpan(
                                                text:
                                                    '\n\n'), // Add spacing between paragraphs
                                          ];
                                        }).toList(),
                                      ),
                                      showCursor: true,
                                      cursorColor: Colors.blue,
                                      enableInteractiveSelection:
                                          true, // Allow multi-paragraph selection
                                    )
                                  : Center(
                                      child: Text(
                                        "No content available",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
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

  String convertSpansToPlainText(List<List<InlineSpan>> content) {
    return content
        .map((spans) => spans.map((span) {
              if (span is TextSpan) {
                return span.text?.trim() ?? '';
              }
              if (span is WidgetSpan) {
                final widget = span.child;
                if (widget is GestureDetector) {
                  final textChild = widget.child as Text?;
                  return textChild?.data?.trim() ?? '';
                }
              }
              return '';
            }).join()) // Combine InlineSpans within a paragraph
        .join('\n\n') // Separate paragraphs by double newlines
        .replaceAll(RegExp(r'\s*\n\s*'), ' ')
        .replaceAll(RegExp(r'^\s*|\s*$'), ''); // Trim the whole string
  }

  Widget _buildCreditSection(String url, String source) {
    String displaySource = source.replaceAll('_', ' ').toUpperCase();

    void launchURL(BuildContext context, String url) async {
      final theme = Theme.of(context);

      try {
        await launchUrl(
          Uri.parse(url),
          customTabsOptions: CustomTabsOptions(
            colorSchemes: CustomTabsColorSchemes.defaults(
              toolbarColor: theme.colorScheme.surface,
            ),
            shareState: CustomTabsShareState.on,
            urlBarHidingEnabled: true,
            showTitle: true,
            closeButton: CustomTabsCloseButton(
              icon: CustomTabsCloseButtonIcons.back,
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        debugPrint('Error opening custom tab: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open the browser.")),
        );
      }
    }

    Future<void> markAsRead() async {
      try {
        final response = await http.post(
          Uri.parse(
              'https://hungrynews-backend.onrender.com/update-news-read-status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'news_id': widget.newsId, // Pass the news_id
            'is_read': 1,
          }),
        );

        if (response.statusCode == 200) {
          if (!mounted) return;
          setState(() {
            isRead = true;
          });
        } else {
          debugPrint('Failed to mark as read: ${response.statusCode}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Failed to update the read status.")),
            );
          }
        }
      } catch (e) {
        debugPrint('Error marking as read: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Error occurred while updating read status.")),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          ElevatedButton.icon(
            onPressed: isRead ? null : markAsRead,
            icon: Icon(
              isRead ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isRead ? Colors.green : Theme.of(context).iconTheme.color,
            ),
            label: Text(
              isRead ? "News read!" : "Finish reading",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isRead ? Colors.green : null,
                  ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                "I want to credit $displaySource for providing this news.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchURL(context, url),
            child: Text(
              "Read more here: $url",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
          const SizedBox(height: 30),
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
