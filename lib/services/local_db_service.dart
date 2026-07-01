import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/visit_model.dart';

/// الخدمة المسؤولة عن كل التعامل مع قاعدة البيانات المحلية (Hive)
/// هذه الخدمة هي مصدر الحقيقة الأساسي لواجهة المستخدم (UI يقرأ منها دائمًا أولًا)
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  late Box<StudentModel> _studentsBox;
  late Box<AttendanceRecord> _attendanceBox;
  late Box<VisitRecord> _visitsBox;

  /// تهيئة Hive وتسجيل الـ Adapters وفتح الصناديق - تُستدعى مرة واحدة عند بدء التطبيق
  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StudentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AttendanceRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(VisitRecordAdapter());
    }
    _studentsBox = await Hive.openBox<StudentModel>(AppConstants.studentsBox);
    _attendanceBox = await Hive.openBox<AttendanceRecord>(AppConstants.attendanceBox);
    _visitsBox = await Hive.openBox<VisitRecord>(AppConstants.visitsBox);
  }

  // ---------------- الشباب ----------------

  List<StudentModel> getAllStudents({bool includeDeleted = false}) {
    final list = _studentsBox.values.toList();
    final filtered = includeDeleted ? list : list.where((s) => !s.isDeleted).toList();
    filtered.sort((a, b) => a.firstName.compareTo(b.firstName));
    return filtered;
  }

  StudentModel? getStudent(String id) => _studentsBox.get(id);

  Future<void> saveStudent(StudentModel student) async {
    await _studentsBox.put(student.id, student);
  }

  Future<void> deleteStudentSoft(String id) async {
    final student = _studentsBox.get(id);
    if (student != null) {
      final updated = student.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        needsSync: true,
      );
      await _studentsBox.put(id, updated);
    }
  }

  /// حذف نهائي محلي (يُستخدم فقط بعد تأكيد المزامنة مع السحابة)
  Future<void> purgeStudent(String id) async {
    await _studentsBox.delete(id);
  }

  List<StudentModel> getStudentsNeedingSync() {
    return _studentsBox.values.where((s) => s.needsSync).toList();
  }

  // ---------------- الحضور ----------------

  List<AttendanceRecord> getAttendanceForDate(String dateKey) {
    return _attendanceBox.values
        .where((a) => a.dateKey == dateKey && !a.isDeleted)
        .toList();
  }

  List<AttendanceRecord> getAttendanceForActivity(String dateKey, String activity) {
    return _attendanceBox.values
        .where((a) => a.dateKey == dateKey && a.activity == activity && !a.isDeleted)
        .toList();
  }

  List<AttendanceRecord> getAttendanceForStudent(String studentId) {
    final list = _attendanceBox.values.where((a) => a.studentId == studentId && !a.isDeleted).toList();
    list.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return list;
  }

  List<AttendanceRecord> getAllAttendance({bool includeDeleted = false}) {
    final list = _attendanceBox.values.toList();
    return includeDeleted ? list : list.where((a) => !a.isDeleted).toList();
  }

  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    await _attendanceBox.put(record.id, record);
  }

  Future<void> saveAttendanceBatch(List<AttendanceRecord> records) async {
    final map = {for (final r in records) r.id: r};
    await _attendanceBox.putAll(map);
  }

  List<AttendanceRecord> getAttendanceNeedingSync() {
    return _attendanceBox.values.where((a) => a.needsSync).toList();
  }

  // ---------------- الافتقاد ----------------

  List<VisitRecord> getVisitsForStudent(String studentId) {
    final list = _visitsBox.values.where((v) => v.studentId == studentId && !v.isDeleted).toList();
    list.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return list;
  }

  List<VisitRecord> getAllVisits({bool includeDeleted = false}) {
    final list = _visitsBox.values.toList();
    return includeDeleted ? list : list.where((v) => !v.isDeleted).toList();
  }

  VisitRecord? getVisit(String id) => _visitsBox.get(id);

  Future<void> saveVisit(VisitRecord visit) async {
    await _visitsBox.put(visit.id, visit);
  }

  List<VisitRecord> getVisitsNeedingSync() {
    return _visitsBox.values.where((v) => v.needsSync).toList();
  }

  Future<void> clearAll() async {
    await _studentsBox.clear();
    await _attendanceBox.clear();
    await _visitsBox.clear();
  }
}
