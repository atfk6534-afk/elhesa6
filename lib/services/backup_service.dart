import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import 'local_db_service.dart';

/// خدمة إنشاء نسخة احتياطية كاملة من بيانات التطبيق (شباب + حضور) واستعادتها
class BackupService {
  final LocalDbService _local;

  BackupService(this._local);

  /// ينشئ ملف نسخة احتياطية JSON ويعيد مساره
  Future<String> createBackup() async {
    final students = _local.getAllStudents(includeDeleted: true);
    final attendance = _local.getAllAttendance(includeDeleted: true);

    final backupData = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'students': students.map((s) => s.toMap()).toList(),
      'attendance': attendance.map((a) => a.toMap()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'attendance_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsString(jsonEncode(backupData));
    return path;
  }

  /// يستعيد البيانات من ملف نسخة احتياطية JSON (يستبدل البيانات الحالية)
  Future<void> restoreBackup(String filePath) async {
    final content = await File(filePath).readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    final studentsRaw = (data['students'] as List<dynamic>? ?? []);
    final attendanceRaw = (data['attendance'] as List<dynamic>? ?? []);

    await _local.clearAll();

    for (final raw in studentsRaw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final student = StudentModel.fromMap(map).copyWith(needsSync: true);
      await _local.saveStudent(student);
    }

    final attendanceRecords = attendanceRaw.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return AttendanceRecord.fromMap(map).copyWith(needsSync: true);
    }).toList();
    await _local.saveAttendanceBatch(attendanceRecords);
  }
}
