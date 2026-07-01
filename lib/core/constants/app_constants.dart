import 'dart:convert';

/// نموذج نشاط مخصص (يضيفه المدير)
class CustomActivity {
  final String id;
  final String name;
  final int points;
  final String timeLabel; // مثال: ٧م - ٨م
  final List<int> weekdays; // 1=اثنين، 3=أربعاء، 5=جمعة، [] = كل الأيام

  const CustomActivity({
    required this.id,
    required this.name,
    required this.points,
    required this.timeLabel,
    required this.weekdays,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'points': points,
        'timeLabel': timeLabel,
        'weekdays': weekdays,
      };

  factory CustomActivity.fromJson(Map<String, dynamic> j) => CustomActivity(
        id: j['id'] as String,
        name: j['name'] as String,
        points: j['points'] as int,
        timeLabel: (j['timeLabel'] as String?) ?? '',
        weekdays: List<int>.from(j['weekdays'] as List),
      );
}

/// نموذج نشاط ثابت في التطبيق
class BuiltinActivity {
  final String name;
  final String timeLabel;
  final List<int> weekdays; // 1=Mon, 3=Wed, 5=Fri
  final int points;
  final IconData? icon; // يُعيّن في الشاشة

  const BuiltinActivity({
    required this.name,
    required this.timeLabel,
    required this.weekdays,
    required this.points,
  }) : icon = null;
}

/// ثوابت عامة للتطبيق
class AppConstants {
  AppConstants._();

  static const String appName = 'متابعة حضور حصة ألحان';

  // Hive boxes
  static const String studentsBox = 'students_box';
  static const String attendanceBox = 'attendance_box';
  static const String settingsBox = 'settings_box';
  static const String pendingOpsBox = 'pending_ops_box';
  static const String visitsBox = 'visits_box';

  // Firestore collections
  static const String studentsCollection = 'students';
  static const String attendanceCollection = 'attendance';
  static const String usersCollection = 'users';
  static const String settingsCollection = 'app_settings';
  static const String visitsCollection = 'visits';

  // Settings keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyFontScale = 'font_scale';
  static const String keyWhatsappMessage = 'whatsapp_message';
  static const String keyCustomActivities = 'custom_activities';

  static const String defaultWhatsappMessage =
      'أهلاً يا {name} ❤️\nافتقدناك النهارده في الحصة، مستنيين نشوفك الأسبوع الجاي بإذن الله.';

  /// تصنيفات لحساب النقاط
  static const String categoryMass = 'قداس';
  static const String categoryTasbeha = 'تسبحة';
  static const String categoryLesson = 'حصة';

  /// الأنشطة الثابتة مع مواعيدها وأيامها
  static const List<Map<String, dynamic>> builtinSchedule = [
    {
      'name': 'قداس الجمعة',
      'timeLabel': '٧ص - ٩ص',
      'weekdays': [5],
      'points': 20,
    },
    {
      'name': 'تسبحة الجمعة',
      'timeLabel': '٨م - ١٠م',
      'weekdays': [5],
      'points': 15,
    },
    {
      'name': 'حصة الألحان الجمعة',
      'timeLabel': '٥م - ٦م',
      'weekdays': [5],
      'points': 10,
    },
    {
      'name': 'حصة الأربعاء',
      'timeLabel': '٧م - ٨م',
      'weekdays': [3],
      'points': 10,
    },
    {
      'name': 'حصة الاثنين',
      'timeLabel': '٨م - ٩م',
      'weekdays': [1],
      'points': 10,
    },
  ];

  /// اسم اليوم بالعربي
  static String dayName(int weekday) {
    const names = {1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس', 5: 'الجمعة', 6: 'السبت', 7: 'الأحد'};
    return names[weekday] ?? '';
  }

  /// النقاط لأي اسم نشاط
  static int pointsForActivity(String activity) {
    for (final b in builtinSchedule) {
      if (b['name'] == activity) return b['points'] as int;
    }
    if (activity.contains(categoryMass)) return 20;
    if (activity.contains(categoryTasbeha)) return 15;
    if (activity.contains(categoryLesson)) return 10;
    return 10;
  }

  static String categoryOf(String activity) {
    if (activity.contains(categoryMass)) return categoryMass;
    if (activity.contains(categoryTasbeha)) return categoryTasbeha;
    if (activity.contains(categoryLesson)) return categoryLesson;
    return activity;
  }

  /// تحليل/حفظ الأنشطة المخصصة كـ JSON
  static List<CustomActivity> parseCustomActivities(String json) {
    if (json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => CustomActivity.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeCustomActivities(List<CustomActivity> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }
}
