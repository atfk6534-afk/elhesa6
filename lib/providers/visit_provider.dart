import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/visit_model.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../core/utils/date_helper.dart';

/// يدير سجلات الافتقاد: قراءة، إضافة ملاحظة افتقاد جديدة، ومزامنتها
class VisitProvider extends ChangeNotifier {
  final LocalDbService _local;
  final SyncService _sync;
  static const _uuid = Uuid();

  VisitProvider(this._local, this._sync) {
    _sync.onDataChanged.listen((_) => notifyListeners());
  }

  List<VisitRecord> getVisitsForStudent(String studentId) {
    return _local.getVisitsForStudent(studentId);
  }

  /// إضافة سجل افتقاد جديد لشاب معين
  Future<void> addVisit({
    required String studentId,
    required String note,
    required String createdBy,
    DateTime? date,
  }) async {
    final now = DateTime.now();
    final visit = VisitRecord(
      id: _uuid.v4(),
      studentId: studentId,
      dateKey: DateHelper.dateKey(date ?? now),
      note: note.trim(),
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      needsSync: true,
    );
    await _local.saveVisit(visit);
    notifyListeners();
    _sync.syncNow();
  }
}
