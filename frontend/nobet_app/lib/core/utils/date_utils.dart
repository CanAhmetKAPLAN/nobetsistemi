import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy', 'tr_TR').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatDateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String toIso(DateTime dt) => dt.toUtc().toIso8601String();
}
