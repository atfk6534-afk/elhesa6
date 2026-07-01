import 'package:url_launcher/url_launcher.dart';

/// مسؤول عن بناء وفتح روابط واتساب الرسمية wa.me
class WhatsappHelper {
  WhatsappHelper._();

  /// ينظف رقم الهاتف ليصبح بصيغة دولية (مصر افتراضيًا +20)
  static String normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) {
      return cleaned.substring(1);
    }
    if (cleaned.startsWith('0')) {
      // رقم مصري محلي يبدأ بصفر -> نستبدلها بكود الدولة 20
      return '20${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('20')) {
      return cleaned;
    }
    return cleaned;
  }

  /// يبني الرسالة باستبدال {name} بالاسم الأول للشاب
  static String buildMessage(String template, String firstName) {
    return template.replaceAll('{name}', firstName);
  }

  /// يفتح واتساب مباشرة على رقم الشاب بالرسالة الجاهزة
  static Future<bool> openWhatsapp({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = normalizePhone(phone);
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$normalizedPhone?text=$encodedMessage');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
