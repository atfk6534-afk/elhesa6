import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../services/firestore_service.dart';
import '../services/connectivity_service.dart';

/// يدير إعدادات التطبيق: الوضع الليلي، حجم الخط، رسالة واتساب، الأنشطة المخصصة
class SettingsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final ConnectivityService _connectivity;
  SharedPreferences? _prefs;

  bool _isDarkMode = false;
  double _fontScale = 1.0;
  String _whatsappMessage = AppConstants.defaultWhatsappMessage;
  List<CustomActivity> _customActivities = [];

  SettingsProvider(this._firestoreService, this._connectivity) {
    _loadSettings();
    _firestoreService.watchWhatsappMessage().listen((message) {
      if (message != null && message.isNotEmpty) {
        _whatsappMessage = message;
        _prefs?.setString(AppConstants.keyWhatsappMessage, message);
        notifyListeners();
      }
    });
  }

  bool get isDarkMode => _isDarkMode;
  double get fontScale => _fontScale;
  String get whatsappMessage => _whatsappMessage;
  List<CustomActivity> get customActivities => _customActivities;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs!.getBool(AppConstants.keyDarkMode) ?? false;
    _fontScale = _prefs!.getDouble(AppConstants.keyFontScale) ?? 1.0;
    _whatsappMessage =
        _prefs!.getString(AppConstants.keyWhatsappMessage) ?? AppConstants.defaultWhatsappMessage;
    final customJson = _prefs!.getString(AppConstants.keyCustomActivities) ?? '';
    _customActivities = AppConstants.parseCustomActivities(customJson);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs?.setBool(AppConstants.keyDarkMode, value);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    await _prefs?.setDouble(AppConstants.keyFontScale, scale);
    notifyListeners();
  }

  Future<void> updateWhatsappMessage(String message) async {
    _whatsappMessage = message;
    await _prefs?.setString(AppConstants.keyWhatsappMessage, message);
    notifyListeners();
    if (await _connectivity.isOnline()) {
      await _firestoreService.pushWhatsappMessage(message);
    }
  }

  Future<void> addCustomActivity(CustomActivity activity) async {
    _customActivities = [..._customActivities, activity];
    await _saveCustomActivities();
  }

  Future<void> removeCustomActivity(String id) async {
    _customActivities = _customActivities.where((a) => a.id != id).toList();
    await _saveCustomActivities();
  }

  Future<void> _saveCustomActivities() async {
    await _prefs?.setString(
        AppConstants.keyCustomActivities, AppConstants.encodeCustomActivities(_customActivities));
    notifyListeners();
  }
}
