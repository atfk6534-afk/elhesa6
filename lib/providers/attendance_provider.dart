import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/student_model.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../core/utils/date_helper.dart';
import '../core/constants/app_constants.dart';

/// يدير تسجيل الحضور وقراءته وحساب الإحصائيات المرتبطة به
class AttendanceProvider extends ChangeNotifier {
  final LocalDbService _local;
  final SyncService _sync;

  AttendanceProvider(this._local, this._sync) {
    _sync.onDataChanged.listen((_) => notifyListeners());
  }

  /// يعيد خريطة studentId -> isPresent لنشاط معين في تاريخ معين
  Map<String, bool> getAttendanceMap(DateTime date, String activity) {
    final dateKey = DateHelper.dateKey(date);
    final records = _local.getAttendanceForActivity(dateKey, activity);
    return {for (final r in records) r.studentId: r.isPresent};
  }

  /// حفظ حضور نشاط كامل لتاريخ معين دفعة واحدة
  Future<void> saveAttendance({
    required DateTime date,
    required String activity,
    required Map<String, bool> studentPresence,
    Map<String, String>? notes,
  }) async {
    final dateKey = DateHelper.dateKey(date);
    final now = DateTime.now();
    final records = studentPresence.entries.map((entry) {
      return AttendanceRecord(
        id: AttendanceRecord.buildId(entry.key, dateKey, activity),
        studentId: entry.key,
        dateKey: dateKey,
        activity: activity,
        isPresent: entry.value,
        note: notes?[entry.key] ?? '',
        updatedAt: now,
        needsSync: true,
      );
    }).toList();

    await _local.saveAttendanceBatch(records);
    notifyListeners();
    _sync.syncNow();
  }

  /// تسجيل حضور/غياب شاب واحد لنشاط وتاريخ معينين مع ملاحظة اختيارية (لشاشة سجل الحضور)
  Future<void> markSingle({
    required String studentId,
    required DateTime date,
    required String activity,
    required bool isPresent,
    String note = '',
  }) async {
    final dateKey = DateHelper.dateKey(date);
    final record = AttendanceRecord(
      id: AttendanceRecord.buildId(studentId, dateKey, activity),
      studentId: studentId,
      dateKey: dateKey,
      activity: activity,
      isPresent: isPresent,
      note: note.trim(),
      updatedAt: DateTime.now(),
      needsSync: true,
    );
    await _local.saveAttendanceRecord(record);
    notifyListeners();
    _sync.syncNow();
  }

  /// كل سجلات الحضور في تاريخ معين (لكل الأنشطة)
  List<AttendanceRecord> getAttendanceForDate(DateTime date) {
    return _local.getAttendanceForDate(DateHelper.dateKey(date));
  }

  List<AttendanceRecord> getAttendanceForStudent(String studentId) {
    return _local.getAttendanceForStudent(studentId);
  }

  /// إحصائيات شاب: عدد الحضور، عدد الغياب، نسبة الالتزام
  ({int present, int absent, double percentage}) studentStats(String studentId) {
    final records = getAttendanceForStudent(studentId);
    final present = records.where((r) => r.isPresent).length;
    final absent = records.where((r) => !r.isPresent).length;
    final total = present + absent;
    final percentage = total == 0 ? 0.0 : (present / total) * 100;
    return (present: present, absent: absent, percentage: percentage);
  }

  /// إجمالي النقاط المكتسبة لشاب معين (مجموع نقاط كل سجلات الحضور الفعلية)
  int totalPoints(String studentId) {
    final records = getAttendanceForStudent(studentId);
    return records.fold(0, (sum, r) => sum + r.points);
  }

  /// آخر سجل حضور فعلي (isPresent = true) لشاب معين، أو null إن لم يحضر أبدًا
  AttendanceRecord? lastAttendance(String studentId) {
    final records = getAttendanceForStudent(studentId).where((r) => r.isPresent).toList();
    if (records.isEmpty) return null;
    records.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return records.first;
  }

  /// سجل الغياب الكامل لشاب معين (الأحدث أولًا)
  List<AttendanceRecord> absenceLog(String studentId) {
    return getAttendanceForStudent(studentId).where((r) => !r.isPresent).toList();
  }

  /// عدد أيام الغياب الفريدة (مهما كان عدد الأنشطة في نفس اليوم)
  int absentDaysCount(String studentId) {
    final dates = absenceLog(studentId).map((r) => r.dateKey).toSet();
    return dates.length;
  }

  /// هل الشاب غاب اليوم عن نشاط واحد على الأقل؟
  bool isAbsentToday(String studentId) {
    final todayKey = DateHelper.dateKey(DateTime.now());
    return absenceLog(studentId).any((r) => r.dateKey == todayKey);
  }

  /// لكل تصنيف (قداس/تسبحة/حصة): هل آخر سجل له كان غياب؟ يُستخدم في شاشة الافتقاد
  /// لمعرفة "غائب عن ماذا بالضبط"
  List<String> missingCategories(String studentId) {
    final records = getAttendanceForStudent(studentId);
    final List<String> missing = [];
    for (final category in AppConstants.attendanceCategories) {
      final categoryRecords = records.where((r) => r.activity.contains(category)).toList();
      if (categoryRecords.isEmpty) continue;
      categoryRecords.sort((a, b) => b.dateKey.compareTo(a.dateKey));
      if (!categoryRecords.first.isPresent) {
        missing.add(category);
      }
    }
    return missing;
  }

  /// إحصائيات اليوم لكل الشباب (لكل الأنشطة المسجلة في هذا اليوم)
  ({int present, int absent, double percentage}) dayStats(DateTime date) {
    final records = getAttendanceForDate(date);
    final present = records.where((r) => r.isPresent).length;
    final absent = records.where((r) => !r.isPresent).length;
    final total = present + absent;
    final percentage = total == 0 ? 0.0 : (present / total) * 100;
    return (present: present, absent: absent, percentage: percentage);
  }

  /// أعلى الشباب التزامًا (مرتبين تنازليًا حسب نسبة الحضور)
  List<MapEntry<StudentModel, double>> topCommitted(List<StudentModel> students, {int limit = 10}) {
    final list = students.map((s) {
      final stats = studentStats(s.id);
      return MapEntry(s, stats.percentage);
    }).toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  /// أكثر الشباب غيابًا (مرتبين تنازليًا حسب عدد مرات الغياب)
  List<MapEntry<StudentModel, int>> mostAbsent(List<StudentModel> students, {int limit = 10}) {
    final list = students.map((s) {
      final stats = studentStats(s.id);
      return MapEntry(s, stats.absent);
    }).toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  /// نسبة حضور كل نشاط على حدة عبر كل التواريخ
  Map<String, double> activityAttendanceRates(List<String> activities) {
    final all = _local.getAllAttendance();
    final Map<String, double> result = {};
    for (final activity in activities) {
      final records = all.where((r) => r.activity == activity).toList();
      if (records.isEmpty) {
        result[activity] = 0;
        continue;
      }
      final present = records.where((r) => r.isPresent).length;
      result[activity] = (present / records.length) * 100;
    }
    return result;
  }

  /// بيانات الحضور عبر الزمن لرسم بياني (آخر [days] يوم بها سجلات)
  List<MapEntry<String, double>> attendanceOverTime({int days = 14}) {
    final all = _local.getAllAttendance();
    final Map<String, List<AttendanceRecord>> byDate = {};
    for (final r in all) {
      byDate.putIfAbsent(r.dateKey, () => []).add(r);
    }
    final sortedKeys = byDate.keys.toList()..sort();
    final lastKeys = sortedKeys.length > days
        ? sortedKeys.sublist(sortedKeys.length - days)
        : sortedKeys;

    return lastKeys.map((key) {
      final records = byDate[key]!;
      final present = records.where((r) => r.isPresent).length;
      final percentage = records.isEmpty ? 0.0 : (present / records.length) * 100;
      return MapEntry(key, percentage);
    }).toList();
  }
}
