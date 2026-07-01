import 'package:hive/hive.dart';

/// نموذج سجل افتقاد: ملاحظة متابعة لشاب معين في تاريخ معين
/// يُستخدم لتسجيل أن خادمًا قام بمحاولة افتقاد/التواصل مع شاب غائب
class VisitRecord {
  final String id;
  final String studentId;
  final String dateKey; // yyyy-MM-dd
  String note;
  String createdBy; // اسم الخادم الذي سجل الافتقاد
  final DateTime createdAt;
  DateTime updatedAt;
  bool needsSync;
  bool isDeleted;

  VisitRecord({
    required this.id,
    required this.studentId,
    required this.dateKey,
    this.note = '',
    this.createdBy = '',
    required this.createdAt,
    required this.updatedAt,
    this.needsSync = true,
    this.isDeleted = false,
  });

  VisitRecord copyWith({
    String? note,
    String? createdBy,
    DateTime? updatedAt,
    bool? needsSync,
    bool? isDeleted,
  }) {
    return VisitRecord(
      id: id,
      studentId: studentId,
      dateKey: dateKey,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'dateKey': dateKey,
      'note': note,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
    };
  }

  factory VisitRecord.fromMap(Map<String, dynamic> map) {
    return VisitRecord(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      dateKey: map['dateKey'] as String,
      note: (map['note'] as String?) ?? '',
      createdBy: (map['createdBy'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isDeleted: (map['isDeleted'] as bool?) ?? false,
      needsSync: false,
    );
  }
}

/// Hive TypeAdapter يدوي
class VisitRecordAdapter extends TypeAdapter<VisitRecord> {
  @override
  final int typeId = 2;

  @override
  VisitRecord read(BinaryReader reader) {
    final map = reader.readMap();
    return VisitRecord(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      dateKey: map['dateKey'] as String,
      note: (map['note'] as String?) ?? '',
      createdBy: (map['createdBy'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isDeleted: (map['isDeleted'] as bool?) ?? false,
      needsSync: (map['needsSync'] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, VisitRecord obj) {
    writer.writeMap({
      'id': obj.id,
      'studentId': obj.studentId,
      'dateKey': obj.dateKey,
      'note': obj.note,
      'createdBy': obj.createdBy,
      'createdAt': obj.createdAt.millisecondsSinceEpoch,
      'updatedAt': obj.updatedAt.millisecondsSinceEpoch,
      'isDeleted': obj.isDeleted,
      'needsSync': obj.needsSync,
    });
  }
}
