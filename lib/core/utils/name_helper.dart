/// يستخرج الاسم الأول (الكلمة الأولى) من الاسم الكامل تلقائيًا
class NameHelper {
  NameHelper._();

  static String extractFirstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.first;
  }
}
