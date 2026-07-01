import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/student_model.dart';
import '../core/utils/name_helper.dart';

/// خدمة تصدير/استيراد بيانات الشباب بصيغة Excel
/// ترتيب الأعمدة: الاسم | الاسم الأول | العنوان | العنوان التفصيلي | رقم ١ (واتساب) | رقم ٢ | ملاحظات
class ExcelService {
  static const _uuid = Uuid();

  Future<String> exportStudents(List<StudentModel> students) async {
    final excel = Excel.createExcel();
    final sheet = excel['الشباب'];

    sheet.appendRow([
      TextCellValue('الاسم الثلاثي'),
      TextCellValue('الاسم الأول'),
      TextCellValue('العنوان'),
      TextCellValue('العنوان التفصيلي'),
      TextCellValue('رقم تليفون أول (واتساب)'),
      TextCellValue('رقم تليفون تاني'),
      TextCellValue('ملاحظات'),
    ]);

    for (final student in students) {
      sheet.appendRow([
        TextCellValue(student.fullName),
        TextCellValue(student.firstName),
        TextCellValue(student.address),
        TextCellValue(student.addressDetail),
        TextCellValue(student.phone),
        TextCellValue(student.phone2),
        TextCellValue(student.notes),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'students_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final path = '${dir.path}/$fileName';
    final fileBytes = excel.encode();
    await File(path).writeAsBytes(fileBytes!);
    return path;
  }

  Future<List<StudentModel>> importStudents(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final List<StudentModel> result = [];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty || row[0]?.value == null) continue;

        final fullName = row[0]?.value.toString().trim() ?? '';
        if (fullName.isEmpty) continue;

        String _cell(int col) =>
            (row.length > col ? row[col]?.value.toString().trim() : null) ?? '';

        final firstName = _cell(1);
        final address = _cell(2);
        final addressDetail = _cell(3);
        final phone = _cell(4);
        final phone2 = _cell(5);
        final notes = _cell(6);

        final now = DateTime.now();
        result.add(StudentModel(
          id: _uuid.v4(),
          fullName: fullName,
          firstName: firstName.isNotEmpty ? firstName : NameHelper.extractFirstName(fullName),
          phone: phone,
          phone2: phone2,
          address: address,
          addressDetail: addressDetail,
          notes: notes,
          createdAt: now,
          updatedAt: now,
          needsSync: true,
        ));
      }
    }
    return result;
  }
}
