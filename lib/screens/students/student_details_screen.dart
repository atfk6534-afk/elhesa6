import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/visit_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../widgets/stat_card.dart';

/// شاشة تفاصيل شاب: بياناته، نقاطه، إحصائياته، سجل الحضور، وقسم الافتقاد الكامل
class StudentDetailsScreen extends StatelessWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final student = studentProvider.getById(studentId);

    if (student == null) {
      return const Scaffold(body: Center(child: Text('هذا الشاب غير موجود')));
    }

    final stats = attendanceProvider.studentStats(studentId);
    final points = attendanceProvider.totalPoints(studentId);
    final lastAttendance = attendanceProvider.lastAttendance(studentId);
    final records = attendanceProvider.getAttendanceForStudent(studentId);

    // تجميع السجلات حسب التاريخ لعرضها كقائمة يومية
    final Map<String, List<dynamic>> byDate = {};
    for (final r in records) {
      byDate.putIfAbsent(r.dateKey, () => []).add(r);
    }
    final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(student.firstName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_off_rounded),
            tooltip: 'الافتقاد',
            onPressed: () => _openVisitSheet(context, studentId: studentId, studentName: student.firstName),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(student.phone, style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    if (student.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(student.address, style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                    if (lastAttendance != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.event_available, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'آخر حضور: ${DateHelper.displayDateWithDay(DateHelper.fromKey(lastAttendance.dateKey))}',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                    if (student.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('ملاحظات: ${student.notes}', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openVisitSheet(context, studentId: studentId, studentName: student.firstName),
                    icon: const Icon(Icons.search_off_rounded),
                    label: const Text('افتقاد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendVisitMessage(context, student: student),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('رسالة افتقاد'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  title: 'مجموع النقاط',
                  value: '$points',
                  icon: Icons.stars_rounded,
                  color: AppColors.warning,
                ),
                StatCard(
                  title: 'نسبة الالتزام',
                  value: '${stats.percentage.toStringAsFixed(0)}%',
                  icon: Icons.percent,
                  color: AppColors.primary,
                ),
                StatCard(
                  title: 'مرات الحضور',
                  value: '${stats.present}',
                  icon: Icons.check_circle,
                  color: AppColors.present,
                ),
                StatCard(
                  title: 'مرات الغياب',
                  value: '${stats.absent}',
                  icon: Icons.cancel,
                  color: AppColors.absent,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('سجل الحضور', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (sortedDates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('لا يوجد سجل حضور بعد')),
              )
            else
              ...sortedDates.map((dateKey) {
                final dayRecords = byDate[dateKey]!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateHelper.displayDateWithDay(DateHelper.fromKey(dateKey)),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...dayRecords.map((r) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  r.isPresent ? Icons.check_circle : Icons.cancel,
                                  size: 18,
                                  color: r.isPresent ? AppColors.present : AppColors.absent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r.isPresent ? "حضر" : "غاب"} ${r.activity}'
                                        '${r.isPresent ? " (+${r.points} نقطة)" : ""}',
                                      ),
                                      if ((r.note as String).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            r.note,
                                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _sendVisitMessage(BuildContext context, {required dynamic student}) async {
    final whatsappMessage = context.read<SettingsProvider>().whatsappMessage;
    final message = WhatsappHelper.buildMessage(whatsappMessage, student.firstName);
    final opened = await WhatsappHelper.openWhatsapp(phone: student.phone, message: message);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب، تأكد من رقم الهاتف')),
      );
    }
  }

  void _openVisitSheet(BuildContext context, {required String studentId, required String studentName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _VisitSheet(studentId: studentId, studentName: studentName),
    );
  }
}

/// محتوى شاشة "الافتقاد": ملخص الغياب + سجل الافتقاد الكامل + إضافة ملاحظة جديدة
class _VisitSheet extends StatefulWidget {
  final String studentId;
  final String studentName;

  const _VisitSheet({required this.studentId, required this.studentName});

  @override
  State<_VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends State<_VisitSheet> {
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    await context.read<VisitProvider>().addVisit(
          studentId: widget.studentId,
          note: _noteController.text,
          createdBy: auth.currentUser?.name ?? '',
        );
    _noteController.clear();
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final visitProvider = context.watch<VisitProvider>();

    final isAbsentToday = attendanceProvider.isAbsentToday(widget.studentId);
    final absentDays = attendanceProvider.absentDaysCount(widget.studentId);
    final lastAttendance = attendanceProvider.lastAttendance(widget.studentId);
    final missing = attendanceProvider.missingCategories(widget.studentId);
    final absenceLog = attendanceProvider.absenceLog(widget.studentId);
    final visits = visitProvider.getVisitsForStudent(widget.studentId);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Text('افتقاد ${widget.studentName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isAbsentToday ? AppColors.absent : AppColors.present).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAbsentToday ? Icons.cancel : Icons.check_circle,
                          color: isAbsentToday ? AppColors.absent : AppColors.present,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAbsentToday ? 'غائب اليوم' : 'غير مسجل غياب اليوم',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('عدد أيام الغياب: $absentDays يوم'),
                    const SizedBox(height: 4),
                    Text(
                      lastAttendance != null
                          ? 'آخر حضور: ${DateHelper.displayDateWithDay(DateHelper.fromKey(lastAttendance.dateKey))}'
                          : 'لم يسجَّل له أي حضور بعد',
                    ),
                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('غائب عن: ${missing.join(' - ')}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('إضافة ملاحظة افتقاد', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'مثال: تواصلت معاه تليفونيًا واطمأنيت عليه...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNote,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('حفظ الملاحظة'),
                ),
              ),
              const SizedBox(height: 20),
              const Text('سجل الافتقاد', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (visits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('لا توجد ملاحظات افتقاد بعد'),
                )
              else
                ...visits.map((v) => Card(
                      child: ListTile(
                        title: Text(v.note),
                        subtitle: Text(
                          '${DateHelper.displayDateWithDay(DateHelper.fromKey(v.dateKey))}'
                          '${v.createdBy.isNotEmpty ? ' - ${v.createdBy}' : ''}',
                        ),
                      ),
                    )),
              const SizedBox(height: 20),
              const Text('سجل الغياب الكامل', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (absenceLog.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('لا يوجد غياب مسجل، الحمد لله'),
                )
              else
                ...absenceLog.map((r) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.cancel, color: AppColors.absent, size: 20),
                      title: Text(r.activity),
                      trailing: Text(DateHelper.displayDate(DateHelper.fromKey(r.dateKey))),
                    )),
            ],
          ),
        );
      },
    );
  }
}
