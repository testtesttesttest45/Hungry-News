import 'package:timezone/timezone.dart' as tz;

class TimeHelper {
  static DateTime get currentTime => tz.TZDateTime.now(tz.getLocation('Asia/Singapore'));
}
