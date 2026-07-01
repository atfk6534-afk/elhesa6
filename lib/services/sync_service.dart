import 'dart:async';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/visit_model.dart';
import 'local_db_service.dart';
import 'firestore_service.dart';
import 'connectivity_service.dart';

/// خدمة المزامنة بين قاعدة البيانات المحلية (Hive) وقاعدة البيانات السحابية (Firestore)
///
/// المبدأ:
/// 1) أي تغيير (إضافة/تعديل/حذف) يُحفظ محليًا فورًا مع وضع needsSync = true.
/// 2) عند توفر الإنترنت يتم رفع كل العناصر التي needsSync = true إلى Firestore.
/// 3) يتم الاستماع لتغييرات Firestore لحظيًا (snapshots) ودمجها محليًا.
/// 4) عند التعارض (نفس العنصر عُدّل محليًا وسحابيًا) يُستخدم مبدأ
///    Last Write Wins بالاعتماد على updatedAt: الأحدث زمنيًا هو الذي يفوز.
class SyncService {
  final LocalDbService _local;
  final FirestoreService _remote;
  final ConnectivityService _connectivity;

  StreamSubscription? _studentsSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _visitsSub;
  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  final StreamController<void> _onDataChanged = StreamController<void>.broadcast();
  Stream<void> get onDataChanged => _onDataChanged.stream;

  SyncService(this._local, this._remote, this._connectivity);

  /// يبدأ الاستماع لكل من الاتصال بالإنترنت وتدفقات Firestore اللحظية
  Future<void> start() async {
    // مزامنة أولية إذا كان هناك اتصال
    if (await _connectivity.isOnline()) {
      await syncNow();
      _listenToRemoteChanges();
    }

    _connectivitySub = _connectivity.onStatusChange.listen((isOnline) async {
      if (isOnline) {
        await syncNow();
        _listenToRemoteChanges();
      } else {
        await _studentsSub?.cancel();
        await _attendanceSub?.cancel();
        await _visitsSub?.cancel();
      }
    });
  }

  void _listenToRemoteChanges() {
    _studentsSub?.cancel();
    _studentsSub = _remote.watchStudents().listen(_mergeRemoteStudents);

    _attendanceSub?.cancel();
    _attendanceSub = _remote.watchAttendance().listen(_mergeRemoteAttendance);

    _visitsSub?.cancel();
    _visitsSub = _remote.watchVisits().listen(_mergeRemoteVisits);
  }

  /// رفع كل التغييرات المعلقة محليًا ثم دمج أي تحديثات بعيدة (يُستخدم عند الطلب اليدوي أيضًا)
  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      if (!await _connectivity.isOnline()) return;
      await _pushPendingStudents();
      await _pushPendingAttendance();
      await _pushPendingVisits();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushPendingStudents() async {
    final pending = _local.getStudentsNeedingSync();
    for (final student in pending) {
      await _remote.pushStudent(student);
      final cleared = student.copyWith(needsSync: false);
      await _local.saveStudent(cleared);
    }
  }

  Future<void> _pushPendingAttendance() async {
    final pending = _local.getAttendanceNeedingSync();
    if (pending.isEmpty) return;
    await _remote.pushAttendanceBatch(pending);
    final cleared = pending.map((r) => r.copyWith(needsSync: false)).toList();
    await _local.saveAttendanceBatch(cleared);
  }

  Future<void> _pushPendingVisits() async {
    final pending = _local.getVisitsNeedingSync();
    if (pending.isEmpty) return;
    await _remote.pushVisitBatch(pending);
    for (final v in pending) {
      await _local.saveVisit(v.copyWith(needsSync: false));
    }
  }

  /// دمج بيانات الشباب القادمة من Firestore مع البيانات المحلية وفق Last Write Wins
  void _mergeRemoteStudents(List<StudentModel> remoteStudents) async {
    bool changed = false;
    for (final remote in remoteStudents) {
      final local = _local.getStudent(remote.id);
      if (local == null) {
        await _local.saveStudent(remote);
        changed = true;
      } else if (local.needsSync) {
        // يوجد تعديل محلي لم يُرفع بعد - يفوز الأحدث زمنيًا
        if (remote.updatedAt.isAfter(local.updatedAt)) {
          await _local.saveStudent(remote);
          changed = true;
        }
        // وإلا: نترك المحلي كما هو، وسيتم رفعه في المزامنة القادمة
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await _local.saveStudent(remote);
        changed = true;
      }
    }
    if (changed) _onDataChanged.add(null);
  }

  /// دمج بيانات الحضور القادمة من Firestore مع البيانات المحلية وفق Last Write Wins
  void _mergeRemoteAttendance(List<AttendanceRecord> remoteRecords) async {
    bool changed = false;
    for (final remote in remoteRecords) {
      final localList = _local.getAttendanceForStudent(remote.studentId);
      AttendanceRecord? local;
      for (final r in localList) {
        if (r.id == remote.id) {
          local = r;
          break;
        }
      }
      if (local == null) {
        await _local.saveAttendanceRecord(remote);
        changed = true;
      } else if (local.needsSync) {
        if (remote.updatedAt.isAfter(local.updatedAt)) {
          await _local.saveAttendanceRecord(remote);
          changed = true;
        }
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await _local.saveAttendanceRecord(remote);
        changed = true;
      }
    }
    if (changed) _onDataChanged.add(null);
  }

  /// دمج سجلات الافتقاد القادمة من Firestore مع البيانات المحلية وفق Last Write Wins
  void _mergeRemoteVisits(List<VisitRecord> remoteVisits) async {
    bool changed = false;
    for (final remote in remoteVisits) {
      final local = _local.getVisit(remote.id);
      if (local == null) {
        await _local.saveVisit(remote);
        changed = true;
      } else if (local.needsSync) {
        if (remote.updatedAt.isAfter(local.updatedAt)) {
          await _local.saveVisit(remote);
          changed = true;
        }
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await _local.saveVisit(remote);
        changed = true;
      }
    }
    if (changed) _onDataChanged.add(null);
  }

  void dispose() {
    _studentsSub?.cancel();
    _attendanceSub?.cancel();
    _visitsSub?.cancel();
    _connectivitySub?.cancel();
    _onDataChanged.close();
  }
}
