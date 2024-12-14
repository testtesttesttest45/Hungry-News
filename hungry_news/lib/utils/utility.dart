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

  // create a composite key for a specific table and news ID
  static String generateCompositeKey(String tableName, int newsId) {
    return '$tableName|$newsId';
  }

  static Future<bool?> getIsRead(String tableName, int newsId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _isReadKey + generateCompositeKey(tableName, newsId);
    return prefs.getBool(key);
  }

  static Future<bool?> getIsSaved(String tableName, int newsId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _isSavedKey + generateCompositeKey(tableName, newsId);
    return prefs.getBool(key);
  }

  static final ValueNotifier<List<Map<String, dynamic>>> savedNewsNotifier =
      ValueNotifier([]);

  static final ValueNotifier<Map<String, bool>> allSavedStatesNotifier =
      ValueNotifier({});

  static Future<void> initializeSavedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedNewsList = prefs.getStringList(_savedNewsListKey);

    if (savedNewsList != null) {
      final savedNews = savedNewsList
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();

      // sync is_read using both global notifier and persisted data
      final updatedSavedNews = savedNews.map((news) {
        final compositeKey =
            generateCompositeKey(news['table_name'], news['news_id']);
        final isReadGlobal = allReadStatesNotifier.value[compositeKey] ?? false;
        final isReadPersisted =
            prefs.getBool(_isReadKey + compositeKey) ?? false;
        return {
          ...news,
          'is_read': isReadGlobal || isReadPersisted, // combine read states
        };
      }).toList();

      updatedSavedNews.sort((a, b) {
        return DateTime.parse(b['datetime'])
            .compareTo(DateTime.parse(a['datetime']));
      });

      savedNewsNotifier.value = updatedSavedNews;

      // populate allSavedStatesNotifier
      final savedStates = {
        for (var news in updatedSavedNews)
          generateCompositeKey(news['table_name'], news['news_id']): true
      };
      allSavedStatesNotifier.value = savedStates;
    } else {
      savedNewsNotifier.value = [];
      allSavedStatesNotifier.value = {};
    }
  }

  static Future<void> setIsSaved(
    String tableName,
    int newsId,
    bool isSaved, {
    Map<String, dynamic>? newsData,
    required DateTime originalDatetime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final compositeKey = generateCompositeKey(tableName, newsId);

    if (isSaved && newsData != null) {
      newsData['datetime'] = originalDatetime.toIso8601String();
      newsData['table_name'] = tableName;

      final currentSavedNews = savedNewsNotifier.value;
      if (!currentSavedNews.any((news) =>
          generateCompositeKey(news['table_name'], news['news_id']) ==
          compositeKey)) {
        savedNewsNotifier.value = [...currentSavedNews, newsData];
      }
    } else {
      savedNewsNotifier.value = savedNewsNotifier.value
          .where((news) =>
              generateCompositeKey(news['table_name'], news['news_id']) !=
              compositeKey)
          .toList();
    }

    final updatedList =
        savedNewsNotifier.value.map((news) => jsonEncode(news)).toList();
    await prefs.setStringList(_savedNewsListKey, updatedList);

    final key = _isSavedKey + compositeKey;
    await prefs.setBool(key, isSaved);

    allSavedStatesNotifier.value = {
      ...allSavedStatesNotifier.value,
      compositeKey: isSaved,
    };

    _sortSavedNewsRespectingFlag();
  }

  static void _sortSavedNewsRespectingFlag() {
    final isReversed = SavedNewsPageState.isReversed;

    savedNewsNotifier.value.sort((a, b) {
      return DateTime.parse(b['datetime'])
          .compareTo(DateTime.parse(a['datetime']));
    });

    if (isReversed) {
      savedNewsNotifier.value = savedNewsNotifier.value.reversed.toList();
    }
  }

  static final ValueNotifier<Map<String, bool>> allReadStatesNotifier =
      ValueNotifier({});

  static Future<void> setIsRead(
      String tableName, int newsId, bool isRead) async {
    final prefs = await SharedPreferences.getInstance();
    final compositeKey = generateCompositeKey(tableName, newsId);

    final key = _isReadKey + compositeKey;
    await prefs.setBool(key, isRead);

    allReadStatesNotifier.value = {
      ...allReadStatesNotifier.value,
      compositeKey: isRead,
    };

    savedNewsNotifier.value = savedNewsNotifier.value.map((news) {
      if (generateCompositeKey(news['table_name'], news['news_id']) ==
          compositeKey) {
        return {
          ...news,
          'is_read': isRead,
        };
      }
      return news;
    }).toList();
  }
}
