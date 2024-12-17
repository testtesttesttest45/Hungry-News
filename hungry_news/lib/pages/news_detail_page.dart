import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:html/dom.dart' as dom;
import '../utils/utility.dart';

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

      void processParagraphs(String selector, {bool excludeAds = true}) {
        document.querySelectorAll(selector).forEach((element) {
          if (excludeAds &&
              (element.text.contains("Advertisement") ||
                  element.text.contains("Copyright") ||
                  element.text.contains("Stay updated") ||
                  element.text.contains("CDATA") ||
                  element.text.contains("script"))) {
            return;
          }

          // Case 1: Handle <p> tags with <br> tags inside
          if (element.localName == 'p') {
            if (element.innerHtml.contains('<br')) {
              final segments = element.innerHtml
                  .split(RegExp(r'<br\s*/?>')) // Split by <br> tags
                  .map((segment) => segment.trim())
                  .where((segment) => segment.isNotEmpty);

              for (final segment in segments) {
                final tempElement = dom.Element.html('<div>$segment</div>');
                final spans = _extractTextAndLinks(
                  tempElement,
                  unescape,
                  context,
                  baseUrl: url,
                );
                if (spans.isNotEmpty) {
                  paragraphs
                      .add(spans); // Add each <br>-split segment as a paragraph
                }
              }
            } else {
              // If no <br>, treat the <p> tag as a single paragraph
              final spans = _extractTextAndLinks(
                element,
                unescape,
                context,
                baseUrl: url,
              );
              if (spans.isNotEmpty) {
                paragraphs.add(spans);
              }
            }
          }
          // Case 2: Handle <div> with nested <p> tags
          else if (element.localName == 'div' &&
              element.querySelectorAll('p').isNotEmpty) {
            element.querySelectorAll('p').forEach((pElement) {
              if (pElement.innerHtml.contains('<br')) {
                final segments = pElement.innerHtml
                    .split(RegExp(r'<br\s*/?>')) // Split by <br> tags
                    .map((segment) => segment.trim())
                    .where((segment) => segment.isNotEmpty);

                for (final segment in segments) {
                  final tempElement = dom.Element.html('<div>$segment</div>');
                  final spans = _extractTextAndLinks(
                    tempElement,
                    unescape,
                    context,
                    baseUrl: url,
                  );
                  if (spans.isNotEmpty) {
                    paragraphs.add(spans);
                  }
                }
              } else {
                final spans = _extractTextAndLinks(
                  pElement,
                  unescape,
                  context,
                  baseUrl: url,
                );
                if (spans.isNotEmpty) {
                  paragraphs.add(spans);
                }
              }
            });
          }
          // Case 3: Handle elements with <br> tags directly
          else if (element.innerHtml.contains('<br')) {
            final segments = element.innerHtml
                .split(RegExp(r'<br\s*/?>'))
                .map((segment) => segment.trim())
                .where((segment) => segment.isNotEmpty);

            for (final segment in segments) {
              final tempElement = dom.Element.html('<div>$segment</div>');
              final spans = _extractTextAndLinks(
                tempElement,
                unescape,
                context,
                baseUrl: url,
              );
              if (spans.isNotEmpty) {
                paragraphs.add(spans);
              }
            }
          }
          // Case 4: Handle plain text in other elements
          else {
            final spans = _extractTextAndLinks(
              element,
              unescape,
              context,
              baseUrl: url,
            );
            if (spans.isNotEmpty) {
              paragraphs.add(spans);
            }
          }
        });
      }

      if (url.contains("bbc.com")) {
        bool videoFound =
            document.querySelector('div[data-component="video-block"]') != null;
        if (videoFound) {
          paragraphs.insert(
            0,
            [
              const TextSpan(
                text:
                    "This article contains video(s). Please use the link at the bottom of this page to view them.\n",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              )
            ],
          );
        }
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
        processParagraphs('div.text-long', excludeAds: true);

        document
            .querySelectorAll('div.text-long img, figure img')
            .forEach((img) {
          final src = img.attributes['src'] ?? '';
          final alt = img.attributes['alt'] ?? 'No caption available';
          if (src.isNotEmpty && src.startsWith('http')) {
            images.add({'src': src, 'alt': unescape.convert(alt)});
          }
        });
      } else {
        processParagraphs('p');

        // extract all images
        document.querySelectorAll('img').forEach((img) {
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
    } else if (response.statusCode == 404) {
      return {
        "content": [
          [
            const TextSpan(
              text: "The requested article could not be found.",
              style: TextStyle(color: Colors.red),
            )
          ]
        ],
        "images": []
      };
    } else {
      return {
        "content": [
          [
            const TextSpan(
              text: "Failed to load content. Please try again later.",
              style: TextStyle(color: Colors.red),
            )
          ]
        ],
        "images": []
      };
    }
  } on SocketException {
    return {
      "content": [
        [
          const TextSpan(
            text:
                "No internet connection. Please check your connection and try again.",
            style: TextStyle(color: Colors.red),
          )
        ]
      ],
      "images": []
    };
  } on TimeoutException {
    return {
      "content": [
        [
          const TextSpan(
            text: "The request timed out. Please try again later.",
            style: TextStyle(color: Colors.red),
          )
        ]
      ],
      "images": []
    };
  } catch (e) {
    return {
      "content": [
        [
          const TextSpan(
            text: "An unexpected error occurred. Please try again later.",
            style: TextStyle(color: Colors.red),
          )
        ]
      ],
      "images": []
    };
  }
}

List<InlineSpan> _extractTextAndLinks(
    dom.Element element, HtmlUnescape unescape, BuildContext context,
    {required String baseUrl}) {
  final spans = <InlineSpan>[];
  var previousNodeWasText = false;

  // we ensures the baseUrl has a valid scheme
  Uri? baseUri;
  try {
    baseUri = Uri.parse(baseUrl);
    if (baseUri.scheme.isEmpty) {
      throw StateError("Base URL lacks a scheme: $baseUrl");
    }
  } catch (e) {
    debugPrint("Invalid base URL: $baseUrl. Error: $e");
    baseUri = null;
  }

  for (var i = 0; i < element.nodes.length; i++) {
    final node = element.nodes[i];

    if (node is dom.Text) {
      final cleanText = unescape
          .convert(node.text.trim())
          .replaceAll(RegExp(r'\s*\n\s*'), ' ')
          .replaceAll(RegExp(r'\s+'), ' '); // normalize the whitespaces

      if (cleanText.isNotEmpty) {
        if (previousNodeWasText) {
          spans.add(const TextSpan(text: ' '));
        }
        spans.add(TextSpan(text: cleanText));
        previousNodeWasText = true;
      }
    } else if (node is dom.Element && node.localName == 'a') {
      var link = node.attributes['href'] ?? '';
      final linkText = unescape.convert(node.text.trim());

      if (link.isNotEmpty && !link.startsWith('http') && baseUri != null) {
        // resolve relative links to absolution
        if (link.startsWith('/')) {
          link = baseUri.origin + link;
        } else {
          link = baseUri.resolve(link).toString();
        }
      }

      if (linkText.isNotEmpty) {
        if (previousNodeWasText) {
          spans.add(const TextSpan(text: ' '));
        }
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

        // add 1 space if the next node is not punctuation
        if (i < element.nodes.length - 1) {
          final nextNode = element.nodes[i + 1];
          if (nextNode is dom.Text) {
            final nextText = nextNode.text.trim();
            if (nextText.isNotEmpty &&
                !RegExp(r'^[.,;!?]').hasMatch(nextText)) {
              spans.add(const TextSpan(text: ' '));
            }
          }
        }
        previousNodeWasText = false;
      }
    } else if (node is dom.Element) {
      // recursive process of nested elements
      final childSpans =
          _extractTextAndLinks(node, unescape, context, baseUrl: baseUrl);
      if (childSpans.isNotEmpty) {
        if (previousNodeWasText) {
          spans.add(const TextSpan(text: ' '));
        }
        spans.addAll(childSpans);
        previousNodeWasText = true;
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
  final DateTime originalDatetime;
  final String tableName;
  final int impactLevel;
  final Function? decrementUnreadCount;

  const NewsDetailPage({
    super.key,
    required this.title,
    required this.url,
    required this.source,
    required this.isSaved,
    required this.newsId,
    required this.isRead,
    required this.originalDatetime,
    required this.tableName,
    required this.impactLevel,
    this.decrementUnreadCount,
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

    _initializeReadAndSavedState();

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isReading = false;
        activeParagraphIndex = null; // Reset state on error
      });
    });
  }

  Future<void> _initializeReadAndSavedState() async {

    final latestIsRead =
        await NewsStateManager.getIsRead(widget.tableName, widget.newsId);
    final latestIsSaved =
        await NewsStateManager.getIsSaved(widget.tableName, widget.newsId);

    setState(() {
      isRead = latestIsRead ?? false;
      isSaved = latestIsSaved ?? false;
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

    // Choose summarized or original content dynamically
    final paragraphs = isSummarized ? summarizedContent : originalContent;
    flutterTts.awaitSpeakCompletion(true);

    flutterTts.setProgressHandler(
        (String currentText, int start, int end, String word) {
      if (!mounted) return;

      for (int i = 0; i < paragraphs.length; i++) {
        final String paragraphText = paragraphs[i]
            .map((span) => (span as TextSpan).text ?? '')
            .join(); // Combine spans into a single string

        if (paragraphText.contains(currentText.trim())) {
          setState(() {
            activeParagraphIndex = i;
          });
          break;
        }
      }
    });

    for (int i = 0; i < paragraphs.length; i++) {
      if (!isReading) break;
      if (!mounted) return;

      final String paragraphText =
          paragraphs[i].map((span) => (span as TextSpan).text ?? '').join();

      await flutterTts.speak(paragraphText.trim());
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
    int summaryLength = (sentences.length / 5).ceil();

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

    final newsData = {
      'news_id': widget.newsId,
      'title': widget.title,
      'url': widget.url,
      'source': widget.source,
      'is_read': isRead,
      'impact_level': widget.impactLevel,
    };

    // update saved state
    await NewsStateManager.setIsSaved(
      widget.tableName,
      widget.newsId,
      newSavedState,
      newsData: newSavedState ? newsData : null,
      originalDatetime: widget.originalDatetime,
    );
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
                  color: widget.impactLevel == 3
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).appBarTheme.backgroundColor,
                  padding: const EdgeInsets.only(
                      top: 40.0, left: 2.0, right: 16.0, bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_circle_left_rounded,
                            size: 32),
                        color: widget.impactLevel == 3
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary,
                        onPressed: () {
                          Navigator.pop(context, {
                            'is_saved': isSaved,
                            'is_read': isRead,
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.impactLevel == 3
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary,
                              ),
                          textAlign: TextAlign.left,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: contentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 275,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Loading content...",
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  );
                } else {
                  final images = snapshot.data?['images'] ?? [];
                  originalContent =
                      snapshot.data?['content'] as List<List<InlineSpan>>;

                  final paragraphs =
                      isSummarized ? summarizedContent : originalContent;
                  final bool hasContent = originalContent.isNotEmpty;

                  return SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        if (images.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 275,
                                  child: Stack(
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
                                          final imageUrl =
                                              images[index]['src']!;
                                          final caption = images[index]['alt']!;

                                          return Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () =>
                                                    _showFullScreenImages(
                                                        images, index),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  child: Image.network(
                                                    imageUrl,
                                                    height: 180,
                                                    fit: BoxFit.cover,
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
                                                      fontStyle:
                                                          FontStyle.italic,
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
                                          left: -20,
                                          top: 75,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.arrow_left,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                            iconSize: 32,
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
                                          right: -20,
                                          top: 75,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.arrow_right,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                            iconSize: 32,
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
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Row(
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
                                label: SizedBox(
                                  width: 80,
                                  child: Text(
                                    isReading ? "Stop reading" : "Read for me",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 130,
                                child: ElevatedButton(
                                  onPressed: !hasContent || isReading
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
                                  child: Text(
                                      isSummarized ? "Original" : "Summarize"),
                                ),
                              ),
                              const SizedBox(width: 5),
                              IconButton(
                                iconSize: 28,
                                onPressed: _toggleBookmark,
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark_added
                                      : Icons.bookmark_add_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: paragraphs.isNotEmpty
                                ? SelectableText.rich(
                                    TextSpan(
                                      children: paragraphs
                                          .asMap()
                                          .entries
                                          .expand((entry) {
                                        final int index = entry.key;
                                        final spans = entry.value;
                                        final isActive =
                                            index == activeParagraphIndex;

                                        return [
                                          TextSpan(
                                            children: spans,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  backgroundColor: isActive
                                                      ? Colors.yellow
                                                          .withOpacity(0.4)
                                                      : Colors.transparent,
                                                ),
                                          ),
                                          const TextSpan(text: '\n\n'),
                                        ];
                                      }).toList(),
                                    ),
                                    showCursor: true,
                                    cursorColor: Colors.blue,
                                    enableInteractiveSelection: true,
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
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: _buildCreditSection(widget.url, widget.source),
                        ),
                      ],
                    ),
                  );
                }
              },
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
                // Preserve the text with proper spacing
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
            }).join(' ')) // Add a space between InlineSpans within a paragraph
        .join('\n\n') // Separate paragraphs by double newlines
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize extra spaces
        .trim(); // Trim the whole string
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
      if (isRead) return;

      setState(() {
        isRead = true;
      });

      // update the read state globally
      await NewsStateManager.setIsRead(widget.tableName, widget.newsId, true);

      // decrement unread count if it meets conditions
      NewsStateManager.decrementUnreadCount(
          widget.tableName, widget.impactLevel);
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
