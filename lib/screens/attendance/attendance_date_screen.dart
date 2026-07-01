import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/settings_provider.dart';
import 'attendance_activity_screen.dart';

/// شاشة اختيار التاريخ ثم النشاط - تعرض الأنشطة المتاحة لليوم فقط
class AttendanceDateScreen extends StatefulWidget {
  const AttendanceDateScreen({super.key});

  @override
  State<AttendanceDateScreen> createState() => _AttendanceDateScreenState();
}

class _AttendanceDateScreenState extends State<AttendanceDateScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  static const _activityIcons = {
    'قداس الجمعة': Icons.church_rounded,
    'تسبحة الجمعة': Icons.music_note_rounded,
    'حصة الألحان الجمعة': Icons.library_music_rounded,
    'حصة الأربعاء': Icons.event_rounded,
    'حصة الاثنين': Icons.event_note_rounded,
  };

  /// يرجع قائمة الأنشطة المتاحة لليوم المحدد (ثابتة + مخصصة)
  List<Map<String, dynamic>> _activitiesForDate(DateTime date, List<CustomActivity> customs) {
    final wd = date.weekday;
    final List<Map<String, dynamic>> result = [];

    // الأنشطة الثابتة
    for (final b in AppConstants.builtinSchedule) {
      final days = b['weekdays'] as List;
      if (days.contains(wd)) {
        result.add({'name': b['name'], 'timeLabel': b['timeLabel'], 'points': b['points'], 'isCustom': false});
      }
    }

    // الأنشطة المخصصة
    for (final c in customs) {
      if (c.weekdays.isEmpty || c.weekdays.contains(wd)) {
        result.add({'name': c.name, 'timeLabel': c.timeLabel, 'points': c.points, 'isCustom': true});
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final customs = context.watch<SettingsProvider>().customActivities;
    final todayActivities = _activitiesForDate(_selectedDate, customs);
    final hasNoActivity = todayActivities.isEmpty;

    // لو مفيش نشاط نعرض كل الأنشطة مع تحذير
    final displayList = hasNoActivity
        ? [
            ...AppConstants.builtinSchedule.map((b) => {
                  'name': b['name'],
                  'timeLabel': b['timeLabel'],
                  'points': b['points'],
                  'isCustom': false,
                }),
            ...customs.map((c) => {'name': c.name, 'timeLabel': c.timeLabel, 'points': c.points, 'isCustom': true}),
          ]
        : todayActivities;

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الحضور')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اختيار التاريخ
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateHelper.displayDateWithDay(_selectedDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.edit_calendar_outlined, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // تحذير إذا لم يكن في اليوم نشاط محدد
              if (hasNoActivity)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.absent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.absent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.absent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'خلي بالك يا باشا! النهاردة (${AppConstants.dayName(_selectedDate.weekday)}) مفيش نشاط محدد',
                          style: const TextStyle(color: AppColors.absent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              Text(
                hasNoActivity ? 'كل الأنشطة المتاحة' : 'أنشطة ${AppConstants.dayName(_selectedDate.weekday)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: displayList.isEmpty
                    ? const Center(child: Text('لا يوجد أنشطة مضافة بعد'))
                    : ListView.separated(
                        itemCount: displayList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = displayList[index];
                          final name = item['name'] as String;
                          final timeLabel = item['timeLabel'] as String;
                          final points = item['points'] as int;
                          final isCustom = item['isCustom'] as bool;

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: Icon(
                                  isCustom
                                      ? Icons.add_circle_outline_rounded
                                      : (_activityIcons[name] ?? Icons.event),
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Row(
                                children: [
                                  if (timeLabel.isNotEmpty) ...[
                                    const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(timeLabel,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(width: 10),
                                  ],
                                  const Icon(Icons.stars_rounded, size: 13, color: AppColors.warning),
                                  const SizedBox(width: 3),
                                  Text('$points نقطة',
                                      style: const TextStyle(fontSize: 12, color: AppColors.warning)),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceActivityScreen(
                                      date: _selectedDate,
                                      activity: name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
