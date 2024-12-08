import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../pages/saved_news_page.dart';

class TimeHelper {
  static DateTime get currentTime =>
      tz.TZDateTime.now(tz.getLocation('Asia/Singapore'));
}

class NewsStateManager {
  static const String _isSavedKey = 'isSaved_';
  static const String _savedNewsListKey = 'savedNews';
  static const String _isReadKey = 'isRead_';

  static Future<bool?> getIsRead(int newsId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isReadKey + newsId.toString());
  }

  // Get the `is_saved` state of a news item
  static Future<bool?> getIsSaved(int newsId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSavedKey + newsId.toString());
  }

  // notifier for saved news
  static final ValueNotifier<List<Map<String, dynamic>>> savedNewsNotifier =
      ValueNotifier([]);

  // notifier for all news saved states (affects Major News Page)
  static final ValueNotifier<Map<int, bool>> allSavedStatesNotifier =
      ValueNotifier({});

  static Future<void> initializeSavedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedNewsList = prefs.getStringList(_savedNewsListKey);

    if (savedNewsList != null) {
      final savedNews = savedNewsList
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();

      // sync is_read using both allReadStatesNotifier and persisted data
      final updatedSavedNews = savedNews.map((news) {
        final isReadGlobal =
            allReadStatesNotifier.value[news['news_id']] ?? false;
        final isReadPersisted =
            prefs.getBool(_isReadKey + news['news_id'].toString()) ?? false;
        return {
          ...news,
          'is_read': isReadGlobal || isReadPersisted, // merge read states
        };
      }).toList();

      // Sort by publishing date, newest first by default, handle for newly saved news to respect sorting state
      updatedSavedNews.sort((a, b) {
        return DateTime.parse(b['datetime'])
            .compareTo(DateTime.parse(a['datetime']));
      });

      savedNewsNotifier.value = updatedSavedNews;

      // Populate allSavedStatesNotifier
      final savedStates = {
        for (var news in updatedSavedNews) news['news_id'] as int: true
      };
      allSavedStatesNotifier.value = savedStates;
    } else {
      savedNewsNotifier.value = [];
      allSavedStatesNotifier.value = {};
    }
  }

  static Future<void> setIsSaved(
    int newsId,
    bool isSaved, {
    Map<String, dynamic>? newsData,
    required DateTime originalDatetime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (isSaved && newsData != null) {
      // update saved news
      newsData['datetime'] = originalDatetime.toIso8601String();
      final currentSavedNews = savedNewsNotifier.value;

      // anti duplicate entry, maybe no need
      if (!currentSavedNews.any((news) => news['news_id'] == newsId)) {
        savedNewsNotifier.value = [...currentSavedNews, newsData];
      }
    } else {
      // remove news from saved list
      savedNewsNotifier.value = savedNewsNotifier.value
          .where((news) => news['news_id'] != newsId)
          .toList();
    }

    final updatedList =
        savedNewsNotifier.value.map((news) => jsonEncode(news)).toList();
    await prefs.setStringList(_savedNewsListKey, updatedList);

    // Update the saved state for the specific news item
    await prefs.setBool(_isSavedKey + newsId.toString(), isSaved);

    // Update allSavedStatesNotifier
    allSavedStatesNotifier.value = {
      ...allSavedStatesNotifier.value,
      newsId: isSaved,
    };

    // Respect the current sorting flag
    _sortSavedNewsRespectingFlag();
  }

  static void _sortSavedNewsRespectingFlag() {
    final isReversed =
        SavedNewsPageState.isReversed; // Access global state flag

    // Sort by publishing date in descending order (most recent first)
    savedNewsNotifier.value.sort((a, b) {
      return DateTime.parse(b['datetime'])
          .compareTo(DateTime.parse(a['datetime']));
    });

    // Reverse the list if `isReversed` is true
    if (isReversed) {
      savedNewsNotifier.value = savedNewsNotifier.value.reversed.toList();
    }
  }

  static final ValueNotifier<Map<int, bool>> allReadStatesNotifier =
      ValueNotifier({});

  static Future<void> setIsRead(int newsId, bool isRead) async {
    final prefs = await SharedPreferences.getInstance();

    // update the read state in persistent storage
    await prefs.setBool(_isReadKey + newsId.toString(), isRead);

    // update the read states notifier
    allReadStatesNotifier.value = {
      ...allReadStatesNotifier.value,
      newsId: isRead,
    };

    savedNewsNotifier.value = savedNewsNotifier.value.map((news) {
      if (news['news_id'] == newsId) {
        return {
          ...news,
          'is_read': isRead,
        };
      }
      return news;
    }).toList();
  }
}
