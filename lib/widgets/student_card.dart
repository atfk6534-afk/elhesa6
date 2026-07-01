import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/student_model.dart';

/// بطاقة عرض شاب واحد في قائمة الشباب
/// تعرض الاسم الأول بخط كبير + الاسم الثلاثي + رقم الهاتف + أزرار (تعديل/حذف/واتساب)
class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onWhatsapp;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
    required this.onWhatsapp,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final canManage = onEdit != null || onDelete != null;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                child: Text(
                  student.firstName.isNotEmpty ? student.firstName[0] : '؟',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.firstName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.fullName,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.phone,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onWhatsapp,
                icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                tooltip: 'واتساب',
              ),
              if (canManage)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) onEdit!();
                    if (value == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    if (onDelete != null)
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
