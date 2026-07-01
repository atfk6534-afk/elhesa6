import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_helper.dart';
import '../../widgets/stat_card.dart';

/// شاشة الإحصائيات الشاملة: حضور اليوم، أعلى التزامًا، أكثر غيابًا، رسم بياني
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().allStudents;
    final attendanceProvider = context.watch<AttendanceProvider>();

    final today = DateTime.now();
    final todayStats = attendanceProvider.dayStats(today);
    final topCommitted = attendanceProvider.topCommitted(students, limit: 10);
    final mostAbsent = attendanceProvider.mostAbsent(students, limit: 10);
    final activityRates = attendanceProvider.activityAttendanceRates(AppConstants.activities);
    final overTime = attendanceProvider.attendanceOverTime(days: 14);

    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                title: 'إجمالي الشباب',
                value: '${students.length}',
                icon: Icons.groups_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                title: 'نسبة الحضور اليوم',
                value: '${todayStats.percentage.toStringAsFixed(0)}%',
                icon: Icons.today_rounded,
                color: AppColors.secondary,
              ),
              StatCard(
                title: 'حضور اليوم',
                value: '${todayStats.present}',
                icon: Icons.check_circle,
                color: AppColors.present,
              ),
              StatCard(
                title: 'غياب اليوم',
                value: '${todayStats.absent}',
                icon: Icons.cancel,
                color: AppColors.absent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (overTime.isNotEmpty) ...[
            const Text('نسبة الحضور خلال الفترة الأخيرة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: (overTime.length / 4).clamp(1, overTime.length).toDouble(),
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= overTime.length) return const SizedBox.shrink();
                              final date = DateHelper.fromKey(overTime[i].key);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 25),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.15)),
                          spots: [
                            for (int i = 0; i < overTime.length; i++) FlSpot(i.toDouble(), overTime[i].value),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text('نسبة حضور كل نشاط', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...activityRates.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: entry.value / 100,
                      minHeight: 10,
                      backgroundColor: AppColors.divider,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${entry.value.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text('أعلى 10 شباب التزامًا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (topCommitted.isEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Text('لا توجد بيانات كافية بعد'))
          else
            ...topCommitted.map((e) => _rankTile(e.key.firstName, '${e.value.toStringAsFixed(0)}%', AppColors.present)),
          const SizedBox(height: 20),
          const Text('أكثر الشباب غيابًا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (mostAbsent.isEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Text('لا توجد بيانات كافية بعد'))
          else
            ...mostAbsent.map((e) => _rankTile(e.key.firstName, '${e.value} مرة', AppColors.absent)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _rankTile(String name, String value, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.person, color: color)),
        title: Text(name),
        trailing: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
