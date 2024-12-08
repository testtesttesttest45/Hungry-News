import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class TimeHelper {
  static DateTime get currentTime => tz.TZDateTime.now(tz.getLocation('Asia/Singapore'));
}

class NewsStateManager {
  static const String _isReadKey = 'isRead_';
  static const String _isSavedKey = 'isSaved_';

  static Future<bool?> getIsRead(int newsId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isReadKey + newsId.toString());
  }

  static Future<bool?> getIsSaved(int newsId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSavedKey + newsId.toString());
  }

  static Future<void> setIsRead(int newsId, bool isRead) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isReadKey + newsId.toString(), isRead);
  }

  static Future<void> setIsSaved(int newsId, bool isSaved) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSavedKey + newsId.toString(), isSaved);
  }
}