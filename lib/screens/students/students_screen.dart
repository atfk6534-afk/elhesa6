import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/student_card.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../providers/settings_provider.dart';
import 'add_edit_student_screen.dart';
import 'student_details_screen.dart';

/// شاشة قائمة الشباب: عرض، بحث، إضافة، تعديل، حذف، واتساب
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف $name؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<StudentProvider>().deleteStudent(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final whatsappMessage = context.watch<SettingsProvider>().whatsappMessage;
    final students = studentProvider.filteredStudents;

    return Scaffold(
      appBar: AppBar(title: const Text('الشباب')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          studentProvider.search('');
                        },
                      )
                    : null,
              ),
              onChanged: studentProvider.search,
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('لا يوجد شباب مسجلين بعد'))
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return StudentCard(
                        student: student,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentDetailsScreen(studentId: student.id),
                          ),
                        ),
                        onEdit: isAdmin
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditStudentScreen(student: student),
                                  ),
                                )
                            : null,
                        onDelete:
                            isAdmin ? () => _confirmDelete(context, student.id, student.firstName) : null,
                        onWhatsapp: () async {
                          final message = WhatsappHelper.buildMessage(whatsappMessage, student.firstName);
                          final opened = await WhatsappHelper.openWhatsapp(
                            phone: student.phone,
                            message: message,
                          );
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تعذر فتح واتساب، تحقق من رقم الهاتف')),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
