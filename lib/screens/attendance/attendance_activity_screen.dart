import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_helper.dart';

/// شاشة تسجيل الحضور لنشاط معين في تاريخ معين
/// تعرض كل الشباب مع Checkbox، الحاضر يظهر بلون أخضر وعلامة صح
/// الغائب يظهر بلون أحمر وعلامة ×، مع عداد حي للحضور والغياب والنسبة
/// ويتم حساب نقاط الحضور تلقائيًا حسب نوع النشاط (قداس/تسبحة/حصة)
class AttendanceActivityScreen extends StatefulWidget {
  final DateTime date;
  final String activity;

  const AttendanceActivityScreen({super.key, required this.date, required this.activity});

  @override
  State<AttendanceActivityScreen> createState() => _AttendanceActivityScreenState();
}

class _AttendanceActivityScreenState extends State<AttendanceActivityScreen> {
  late Map<String, bool> _presence;
  late Map<String, String> _notes;
  bool _isSaving = false;
  bool _initialized = false;

  Future<void> _editNote(String studentId, String studentName) async {
    final controller = TextEditingController(text: _notes[studentId] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ملاحظة حضور $studentName'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ملاحظة اختيارية...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _notes[studentId] = result.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final students = context.watch<StudentProvider>().allStudents;
    final activityPoints = AppConstants.pointsForActivity(widget.activity);

    if (!_initialized) {
      final existing = attendanceProvider.getAttendanceMap(widget.date, widget.activity);
      _presence = {for (final s in students) s.id: existing[s.id] ?? false};
      _notes = {};
      _initialized = true;
    }

    final presentCount = _presence.values.where((v) => v).length;
    final totalCount = students.length;
    final absentCount = totalCount - presentCount;
    final percentage = totalCount == 0 ? 0.0 : (presentCount / totalCount) * 100;

    return Scaffold(
      appBar: AppBar(title: Text(widget.activity)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    DateHelper.displayDateWithDay(widget.date),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (activityPoints > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'نقاط الحضور لهذا النشاط: $activityPoints نقطة',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _miniStat('حضور', '$presentCount', AppColors.present),
                      _miniStat('غياب', '$absentCount', AppColors.absent),
                      _miniStat('النسبة', '${percentage.toStringAsFixed(0)}%', AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('لا يوجد شباب مسجلين بعد'))
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isPresent = _presence[student.id] ?? false;
                        final hasNote = (_notes[student.id] ?? '').isNotEmpty;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isPresent ? AppColors.present : AppColors.absent)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isPresent ? AppColors.present : AppColors.absent)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isPresent,
                            onChanged: (value) {
                              setState(() => _presence[student.id] = value ?? false);
                            },
                            activeColor: AppColors.present,
                            title: Text(student.firstName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              isPresent && activityPoints > 0
                                  ? '${student.fullName} • +$activityPoints نقطة'
                                  : student.fullName,
                            ),
                            secondary: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    hasNote ? Icons.edit_note : Icons.note_add_outlined,
                                    color: hasNote ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  tooltip: 'إضافة ملاحظة',
                                  onPressed: () => _editNote(student.id, student.firstName),
                                ),
                                Icon(
                                  isPresent ? Icons.check_circle : Icons.cancel,
                                  color: isPresent ? AppColors.present : AppColors.absent,
                                ),
                              ],
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: const Text('حفظ الحضور'),
              onPressed: students.isEmpty || _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      await context.read<AttendanceProvider>().saveAttendance(
                            date: widget.date,
                            activity: widget.activity,
                            studentPresence: _presence,
                            notes: _notes,
                          );
                      if (mounted) {
                        setState(() => _isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ الحضور بنجاح')),
                        );
                        Navigator.pop(context);
                      }
                    },
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
