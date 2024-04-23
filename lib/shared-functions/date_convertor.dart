import 'package:intl/intl.dart';

class DateConverter {
  static String djangoDateTimeToNormalDate(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return DateFormat('MM/dd/yyyy').format(dateTime);
  }

  static String djangoDateToNormalDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return DateFormat('MM/dd/yyyy').format(date);
  }

  static String formatChatTime(DateTime timestamp) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(timestamp);
    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    }
    if (timestamp.day == now.day &&
        timestamp.month == now.month &&
        timestamp.year == now.year) {
      return DateFormat('HH:mm').format(timestamp);
    }
    if (timestamp.day == now.day - 1 &&
        timestamp.month == now.month &&
        timestamp.year == now.year) {
      return 'Yesterday';
    }
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }
}
