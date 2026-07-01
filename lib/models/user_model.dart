/// أدوار المستخدمين في التطبيق
enum UserRole { admin, servant }

UserRole roleFromString(String value) {
  return value == 'admin' ? UserRole.admin : UserRole.servant;
}

String roleToString(UserRole role) {
  return role == UserRole.admin ? 'admin' : 'servant';
}

/// نموذج بيانات الخادم/المدير المسجل دخوله
class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      role: roleFromString((map['role'] as String?) ?? 'servant'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': roleToString(role),
    };
  }
}
