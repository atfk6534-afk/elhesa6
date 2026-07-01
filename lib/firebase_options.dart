// ignore_for_file: type=lint
// ⚠️ هذا ملف placeholder فقط.
// يجب توليد هذا الملف تلقائيًا بالقيم الحقيقية الخاصة بمشروعك على Firebase
// عن طريق تشغيل الأمر التالي من جذر المشروع بعد تثبيت FlutterFire CLI:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// سيقوم هذا الأمر تلقائيًا باستبدال هذا الملف بالقيم الصحيحة المرتبطة
// بمشروع Firebase الخاص بك (apiKey, appId, projectId... إلخ)
// راجع ملف README.md في جذر المشروع لمزيد من التفاصيل.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('هذا التطبيق مخصص لأندرويد فقط ولا يدعم الويب حاليًا.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('هذا التطبيق مخصص لأندرويد فقط حاليًا.');
    }
  }

  // ⚠️ استبدل القيم التالية بالقيم الحقيقية من Firebase Console
  // (Project Settings -> Your apps -> Android app)
  // أو استخدم أمر flutterfire configure لتوليدها تلقائيًا
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDKo909KwNJLuLrH37EDorxt2hsFyplyR8',
    appId: '1:310946824096:android:58e067698e145b8e04aec5',
    messagingSenderId: '310946824096',
    projectId: 'elhesa-42b95',
    storageBucket: 'elhesa-42b95.firebasestorage.app',
  );
}
