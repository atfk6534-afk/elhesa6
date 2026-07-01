import 'package:hive/hive.dart';

/// نموذج بيانات الشاب
class StudentModel {
  final String id;
  String fullName;
  String firstName;
  String phone;       // رقم تليفون أول (واتساب)
  String phone2;      // رقم تليفون تاني
  String address;     // العنوان
  String addressDetail; // العنوان التفصيلي
  String notes;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
  bool needsSync;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.phone,
    this.phone2 = '',
    this.address = '',
    this.addressDetail = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.needsSync = true,
  });

  StudentModel copyWith({
    String? fullName,
    String? firstName,
    String? phone,
    String? phone2,
    String? address,
    String? addressDetail,
    String? notes,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? needsSync,
  }) {
    return StudentModel(
      id: id,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'firstName': firstName,
      'phone': phone,
      'phone2': phone2,
      'address': address,
      'addressDetail': addressDetail,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      firstName: map['firstName'] as String,
      phone: map['phone'] as String,
      phone2: (map['phone2'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      addressDetail: (map['addressDetail'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isDeleted: (map['isDeleted'] as bool?) ?? false,
      needsSync: false,
    );
  }
}

class StudentModelAdapter extends TypeAdapter<StudentModel> {
  @override
  final int typeId = 0;

  @override
  StudentModel read(BinaryReader reader) {
    final map = reader.readMap();
    return StudentModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      firstName: map['firstName'] as String,
      phone: map['phone'] as String,
      phone2: (map['phone2'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      addressDetail: (map['addressDetail'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isDeleted: (map['isDeleted'] as bool?) ?? false,
      needsSync: (map['needsSync'] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, StudentModel obj) {
    writer.writeMap({
      'id': obj.id,
      'fullName': obj.fullName,
      'firstName': obj.firstName,
      'phone': obj.phone,
      'phone2': obj.phone2,
      'address': obj.address,
      'addressDetail': obj.addressDetail,
      'notes': obj.notes,
      'createdAt': obj.createdAt.millisecondsSinceEpoch,
      'updatedAt': obj.updatedAt.millisecondsSinceEpoch,
      'isDeleted': obj.isDeleted,
      'needsSync': obj.needsSync,
    });
  }
}
