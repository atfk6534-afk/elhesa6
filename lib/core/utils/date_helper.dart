import 'package:intl/intl.dart';

/// تنسيق وتحويل التواريخ المستخدمة في التطبيق
class DateHelper {
  DateHelper._();

  /// المفتاح المستخدم لتخزين الحضور: yyyy-MM-dd (ثابت بغض النظر عن اللغة)
  static String dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// عرض التاريخ بصيغة عربية مقروءة: 15/7/2026
  static String displayDate(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }

  /// عرض التاريخ مع اسم اليوم بالعربية
  static String displayDateWithDay(DateTime date) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dayName = days[date.weekday - 1];
    return '$dayName ${displayDate(date)}';
  }

  static DateTime fromKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}
