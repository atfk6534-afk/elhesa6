import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/excel_service.dart';
import '../../services/backup_service.dart';
import '../../services/local_db_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'manage_servants_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _excelService = ExcelService();
  static const _uuid = Uuid();
  bool _isBusy = false;

  // =================== واتساب ===================
  Future<void> _editWhatsappMessage() async {
    final settings = context.read<SettingsProvider>();
    final controller = TextEditingController(text: settings.whatsappMessage);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل رسالة واتساب'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('استخدم {name} ليتم استبدالها باسم الشاب الأول', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          TextField(controller: controller, maxLines: 4),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('حفظ')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await settings.updateWhatsappMessage(result.trim());
    }
  }

  // =================== إضافة نشاط مخصص ===================
  Future<void> _addCustomActivity() async {
    final nameCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '10');
    final selectedDays = <int>{};

    const dayNames = {1: 'الاثنين', 3: 'الأربعاء', 5: 'الجمعة', 7: 'الأحد', 6: 'السبت', 4: 'الخميس', 2: 'الثلاثاء'};

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('إضافة نشاط جديد'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم النشاط *')),
              const SizedBox(height: 12),
              TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'الميعاد (مثال: ٧م - ٨م)')),
              const SizedBox(height: 12),
              TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'النقاط'),
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerRight, child: Text('الأيام (فاضي = كل الأيام):')),
              Wrap(
                spacing: 6,
                children: dayNames.entries.map((e) {
                  final selected = selectedDays.contains(e.key);
                  return FilterChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (v) => setSt(() => v ? selectedDays.add(e.key) : selectedDays.remove(e.key)),
                  );
                }).toList(),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة')),
          ],
        ),
      ),
    );

    if (result != true || nameCtrl.text.trim().isEmpty) return;

    final activity = CustomActivity(
      id: _uuid.v4(),
      name: nameCtrl.text.trim(),
      timeLabel: timeCtrl.text.trim(),
      points: int.tryParse(pointsCtrl.text.trim()) ?? 10,
      weekdays: selectedDays.toList(),
    );
    await context.read<SettingsProvider>().addCustomActivity(activity);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة "${activity.name}"')));
  }

  // =================== Excel ===================
  Future<void> _exportExcel() async {
    setState(() => _isBusy = true);
    try {
      final students = context.read<StudentProvider>().allStudents;
      final path = await _excelService.exportStudents(students);
      await Share.shareXFiles([XFile(path)], text: 'تصدير بيانات الشباب');
    } catch (e) {
      _showError('فشل التصدير: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importExcel() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result == null || result.files.single.path == null) return;
    setState(() => _isBusy = true);
    try {
      final imported = await _excelService.importStudents(result.files.single.path!);
      final provider = context.read<StudentProvider>();
      for (final student in imported) {
        await provider.addStudent(
          fullName: student.fullName,
          phone: student.phone,
          phone2: student.phone2,
          address: student.address,
          addressDetail: student.addressDetail,
          notes: student.notes,
          customFirstName: student.firstName,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تم استيراد ${imported.length} شاب بنجاح')));
      }
    } catch (e) {
      _showError('فشل الاستيراد: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // =================== حذف كل الشباب ===================
  Future<void> _deleteAllStudents() async {
    final count = context.read<StudentProvider>().allStudents.length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مفيش شباب مسجلين أصلاً')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ حذف كل الشباب'),
        content: Text(
          'هيتم حذف $count شاب دفعة واحدة.\nالعملية دي مش هترجع، هل أنت متأكد؟',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isBusy = true);
    try {
      await context.read<StudentProvider>().deleteAllStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف كل الشباب')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // =================== نسخ احتياطي ===================
  Future<void> _createBackup() async {
    setState(() => _isBusy = true);
    try {
      final backupService = BackupService(LocalDbService());
      final path = await backupService.createBackup();
      await Share.shareXFiles([XFile(path)], text: 'نسخة احتياطية');
    } catch (e) {
      _showError('فشل إنشاء النسخة الاحتياطية: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: const Text('سيتم استبدال جميع البيانات الحالية. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('متابعة')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;
    setState(() => _isBusy = true);
    try {
      final backupService = BackupService(LocalDbService());
      await backupService.restoreBackup(result.files.single.path!);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم استعادة النسخة الاحتياطية بنجاح')));
      }
    } catch (e) {
      _showError('فشل الاستعادة: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.absent));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final customs = settings.customActivities;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: AbsorbPointer(
        absorbing: _isBusy,
        child: Opacity(
          opacity: _isBusy ? 0.6 : 1,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (isAdmin) ...[
                _sectionTitle('عام'),
                ListTile(
                  leading: const Icon(Icons.message_outlined),
                  title: const Text('تعديل رسالة واتساب'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: _editWhatsappMessage,
                ),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('إدارة الخدام'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageServantsScreen())),
                ),
                const Divider(),
                _sectionTitle('الأنشطة المخصصة'),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  title: const Text('إضافة نشاط جديد'),
                  onTap: _addCustomActivity,
                ),
                if (customs.isNotEmpty)
                  ...customs.map((c) => ListTile(
                        leading: const Icon(Icons.event_note_outlined),
                        title: Text(c.name),
                        subtitle: Text(
                          '${c.timeLabel.isNotEmpty ? "${c.timeLabel} • " : ""}${c.points} نقطة'
                          '${c.weekdays.isEmpty ? " • كل الأيام" : ""}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.absent),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('حذف "${c.name}"؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
                                  ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
                                ],
                              ),
                            );
                            if (ok == true) await context.read<SettingsProvider>().removeCustomActivity(c.id);
                          },
                        ),
                      )),
                const Divider(),
                _sectionTitle('البيانات'),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('تصدير Excel'),
                  onTap: _exportExcel,
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('استيراد Excel'),
                  onTap: _importExcel,
                ),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('إنشاء نسخة احتياطية'),
                  onTap: _createBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('استعادة النسخة الاحتياطية'),
                  onTap: _restoreBackup,
                ),
                const Divider(),
                _sectionTitle('الخطر ⚠️'),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.absent),
                  title: const Text('حذف كل الشباب', style: TextStyle(color: AppColors.absent)),
                  subtitle: const Text('احذر! العملية دي مش بترجع'),
                  onTap: _deleteAllStudents,
                ),
                const Divider(),
              ],
              _sectionTitle('المظهر'),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('الوضع الليلي'),
                value: settings.isDarkMode,
                onChanged: settings.toggleDarkMode,
              ),
              ListTile(
                leading: const Icon(Icons.text_fields_rounded),
                title: const Text('حجم الخط'),
                subtitle: Slider(
                  value: settings.fontScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  label: settings.fontScale.toStringAsFixed(1),
                  onChanged: settings.setFontScale,
                ),
              ),
              if (_isBusy)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
    );
  }
}
