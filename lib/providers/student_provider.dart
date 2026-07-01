import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/student_model.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../core/utils/name_helper.dart';

class StudentProvider extends ChangeNotifier {
  final LocalDbService _local;
  final SyncService _sync;
  static const _uuid = Uuid();

  List<StudentModel> _students = [];
  String _searchQuery = '';

  StudentProvider(this._local, this._sync) {
    _loadFromLocal();
    _sync.onDataChanged.listen((_) => _loadFromLocal());
  }

  List<StudentModel> get allStudents => _students;

  List<StudentModel> get filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    final q = _searchQuery.trim().toLowerCase();
    return _students.where((s) {
      return s.firstName.toLowerCase().contains(q) ||
          s.fullName.toLowerCase().contains(q) ||
          s.phone.contains(q) ||
          s.phone2.contains(q);
    }).toList();
  }

  void _loadFromLocal() {
    _students = _local.getAllStudents();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  StudentModel? getById(String id) => _local.getStudent(id);

  Future<void> addStudent({
    required String fullName,
    required String phone,
    String phone2 = '',
    String address = '',
    String addressDetail = '',
    String notes = '',
    String? customFirstName,
  }) async {
    final now = DateTime.now();
    final student = StudentModel(
      id: _uuid.v4(),
      fullName: fullName.trim(),
      firstName: (customFirstName != null && customFirstName.trim().isNotEmpty)
          ? customFirstName.trim()
          : NameHelper.extractFirstName(fullName),
      phone: phone.trim(),
      phone2: phone2.trim(),
      address: address.trim(),
      addressDetail: addressDetail.trim(),
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
      needsSync: true,
    );
    await _local.saveStudent(student);
    _loadFromLocal();
    _sync.syncNow();
  }

  Future<void> updateStudent(StudentModel student) async {
    final updated = student.copyWith(updatedAt: DateTime.now(), needsSync: true);
    await _local.saveStudent(updated);
    _loadFromLocal();
    _sync.syncNow();
  }

  Future<void> deleteStudent(String id) async {
    await _local.deleteStudentSoft(id);
    _loadFromLocal();
    _sync.syncNow();
  }

  /// حذف كل الشباب دفعة واحدة
  Future<void> deleteAllStudents() async {
    final all = _local.getAllStudents();
    for (final s in all) {
      await _local.deleteStudentSoft(s.id);
    }
    _loadFromLocal();
    _sync.syncNow();
  }

  Future<void> manualSync() => _sync.syncNow();
}
