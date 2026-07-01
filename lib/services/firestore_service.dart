import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/visit_model.dart';

/// الخدمة المسؤولة عن كل القراءة/الكتابة من وإلى Firestore
/// تُستخدم بشكل أساسي من قبل SyncService وليس مباشرة من الواجهات
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _db.collection(AppConstants.studentsCollection);

  CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _db.collection(AppConstants.attendanceCollection);

  CollectionReference<Map<String, dynamic>> get _visitsRef =>
      _db.collection(AppConstants.visitsCollection);

  // ---------------- الشباب ----------------

  Future<void> pushStudent(StudentModel student) async {
    await _studentsRef.doc(student.id).set(student.toMap(), SetOptions(merge: true));
  }

  Future<List<StudentModel>> fetchAllStudents() async {
    final snapshot = await _studentsRef.get();
    return snapshot.docs.map((d) => StudentModel.fromMap(d.data())).toList();
  }

  /// مراقبة تغييرات الشباب لحظيًا (Live Sync بين أجهزة الخدام)
  Stream<List<StudentModel>> watchStudents() {
    return _studentsRef.snapshots().map(
          (snap) => snap.docs.map((d) => StudentModel.fromMap(d.data())).toList(),
        );
  }

  // ---------------- الحضور ----------------

  Future<void> pushAttendance(AttendanceRecord record) async {
    await _attendanceRef.doc(record.id).set(record.toMap(), SetOptions(merge: true));
  }

  Future<void> pushAttendanceBatch(List<AttendanceRecord> records) async {
    final batch = _db.batch();
    for (final record in records) {
      batch.set(_attendanceRef.doc(record.id), record.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<AttendanceRecord>> fetchAllAttendance() async {
    final snapshot = await _attendanceRef.get();
    return snapshot.docs.map((d) => AttendanceRecord.fromMap(d.data())).toList();
  }

  /// مراقبة تغييرات الحضور لحظيًا (Live Sync بين أجهزة الخدام)
  Stream<List<AttendanceRecord>> watchAttendance() {
    return _attendanceRef.snapshots().map(
          (snap) => snap.docs.map((d) => AttendanceRecord.fromMap(d.data())).toList(),
        );
  }

  // ---------------- الافتقاد ----------------

  Future<void> pushVisit(VisitRecord visit) async {
    await _visitsRef.doc(visit.id).set(visit.toMap(), SetOptions(merge: true));
  }

  Future<void> pushVisitBatch(List<VisitRecord> visits) async {
    final batch = _db.batch();
    for (final visit in visits) {
      batch.set(_visitsRef.doc(visit.id), visit.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// مراقبة تغييرات سجلات الافتقاد لحظيًا (Live Sync بين أجهزة الخدام)
  Stream<List<VisitRecord>> watchVisits() {
    return _visitsRef.snapshots().map(
          (snap) => snap.docs.map((d) => VisitRecord.fromMap(d.data())).toList(),
        );
  }

  // ---------------- إعدادات التطبيق المشتركة (رسالة واتساب) ----------------

  Future<void> pushWhatsappMessage(String message) async {
    await _db.collection(AppConstants.settingsCollection).doc('shared').set(
      {'whatsappMessage': message},
      SetOptions(merge: true),
    );
  }

  Stream<String?> watchWhatsappMessage() {
    return _db.collection(AppConstants.settingsCollection).doc('shared').snapshots().map(
          (doc) => doc.data()?['whatsappMessage'] as String?,
        );
  }
}
