import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/home_menu_card.dart';
import '../students/students_screen.dart';
import '../attendance/attendance_date_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';

/// الشاشة الرئيسية: تعرض بطاقات التنقل لكل أقسام التطبيق
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشاشة الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أهلاً ${user?.name.isNotEmpty == true ? user!.name : 'بك'} 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user?.isAdmin == true ? 'حساب مدير' : 'حساب خادم',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.05,
                  children: [
                    HomeMenuCard(
                      title: 'الشباب',
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentsScreen()),
                      ),
                    ),
                    HomeMenuCard(
                      title: 'الحضور',
                      icon: Icons.fact_check_rounded,
                      color: AppColors.present,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceDateScreen()),
                      ),
                    ),
                    HomeMenuCard(
                      title: 'الإحصائيات',
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.secondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                      ),
                    ),
                    HomeMenuCard(
                      title: 'الإعدادات',
                      icon: Icons.settings_rounded,
                      color: const Color(0xFF6C5B7B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
