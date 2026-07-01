import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_colors.dart';

/// شاشة يديرها المدير لإضافة أو حذف حسابات الخدام
class ManageServantsScreen extends StatefulWidget {
  const ManageServantsScreen({super.key});

  @override
  State<ManageServantsScreen> createState() => _ManageServantsScreenState();
}

class _ManageServantsScreenState extends State<ManageServantsScreen> {
  final _authService = AuthService();
  List<AppUser> _servants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServants();
  }

  Future<void> _loadServants() async {
    setState(() => _isLoading = true);
    _servants = await _authService.getAllServants();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addServantDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.servant;

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('إضافة خادم جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'كلمة المرور (6 أحرف على الأقل)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'الصلاحية'),
                  items: const [
                    DropdownMenuItem(value: UserRole.servant, child: Text('خادم')),
                    DropdownMenuItem(value: UserRole.admin, child: Text('مدير')),
                  ],
                  onChanged: (value) => setStateDialog(() => selectedRole = value ?? UserRole.servant),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isEmpty || passwordController.text.length < 6) return;
                try {
                  await _authService.addServant(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    name: nameController.text.trim(),
                    role: selectedRole,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('فشلت الإضافة: $e')));
                  }
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (added == true) _loadServants();
  }

  Future<void> _removeServant(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف صلاحية ${user.name.isEmpty ? user.email : user.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _authService.removeServant(user.uid);
      _loadServants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الخدام')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServants,
              child: _servants.isEmpty
                  ? ListView(children: const [
                      Padding(padding: EdgeInsets.all(40), child: Center(child: Text('لا يوجد خدام مضافين بعد')))
                    ])
                  : ListView.builder(
                      itemCount: _servants.length,
                      itemBuilder: (context, index) {
                        final user = _servants[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.isAdmin
                                  ? AppColors.secondary.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              child: Icon(
                                user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
                                color: user.isAdmin ? AppColors.secondary : AppColors.primary,
                              ),
                            ),
                            title: Text(user.name.isEmpty ? user.email : user.name),
                            subtitle: Text('${user.email} • ${user.isAdmin ? "مدير" : "خادم"}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeServant(user),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addServantDialog,
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
}
