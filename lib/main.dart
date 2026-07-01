import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'core/theme/app_theme.dart';

import 'services/local_db_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';

import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/visit_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تثبيت اتجاه التطبيق على الوضع الرأسي فقط لتجربة استخدام أفضل على الهاتف
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تهيئة قاعدة البيانات المحلية (Hive) - أساس العمل بدون إنترنت
  final localDb = LocalDbService();
  await localDb.init();

  // تهيئة باقي الخدمات الأساسية
  final authService = AuthService();
  final firestoreService = FirestoreService();
  final connectivityService = ConnectivityService();
  final syncService = SyncService(localDb, firestoreService, connectivityService);

  // بدء نظام المزامنة في الخلفية (يعمل تلقائيًا عند توفر الإنترنت)
  syncService.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => StudentProvider(localDb, syncService)),
        ChangeNotifierProvider(create: (_) => AttendanceProvider(localDb, syncService)),
        ChangeNotifierProvider(create: (_) => VisitProvider(localDb, syncService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(firestoreService, connectivityService)),
      ],
      child: const LahanAttendanceApp(),
    ),
  );
}

/// الويدجت الجذري للتطبيق - يحدد الثيم واللغة والاتجاه (RTL)
class LahanAttendanceApp extends StatelessWidget {
  const LahanAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'متابعة حضور حصة ألحان',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme(settings.fontScale),
      darkTheme: AppTheme.darkTheme(settings.fontScale),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AuthWrapper(),
    );
  }
}
