import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// خدمة بسيطة لمراقبة حالة الاتصال بالإنترنت
/// تُستخدم لتشغيل المزامنة التلقائية بمجرد عودة الاتصال
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();

  Stream<bool> get onStatusChange => _statusController.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      _statusController.add(isOnline);
    });
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void dispose() {
    _statusController.close();
  }
}
