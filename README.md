# تطبيق متابعة حضور حصة ألحان 3 إعدادي و1 ثانوي

تطبيق Flutter كامل (Android فقط) لمتابعة حضور وغياب الشباب في حصة الألحان، يعمل بدون إنترنت (Offline First) ويتزامن تلقائيًا مع Firebase عند توفر الاتصال.

## المتطلبات قبل البدء

- Flutter SDK (آخر إصدار مستقر، 3.27 أو أحدث) — https://docs.flutter.dev/get-started/install
- حساب Google لإنشاء مشروع على [Firebase Console](https://console.firebase.google.com)
- Android Studio (لتشغيل المحاكي أو لإدارة SDK الخاص بأندرويد)

## الخطوة 1: تثبيت الحزم

```bash
flutter pub get
```

## الخطوة 2: إعداد Firebase (خطوة إلزامية قبل التشغيل)

المشروع حاليًا يحتوي على ملفات Firebase placeholder (`lib/firebase_options.dart` و `android/app/google-services.json`) ويجب استبدالها بالقيم الحقيقية الخاصة بك:

1. أنشئ مشروعًا جديدًا في [Firebase Console](https://console.firebase.google.com).
2. فعّل **Authentication** ← طريقة تسجيل الدخول: **Email/Password**.
3. فعّل **Cloud Firestore** ← ابدأ في وضع الإنتاج (production mode).
4. ثبّت أدوات FlutterFire إن لم تكن مثبتة:
   ```bash
   dart pub global activate flutterfire_cli
   ```
5. من جذر المشروع نفّذ:
   ```bash
   flutterfire configure
   ```
   اختر مشروع Firebase الذي أنشأته، واختر **Android** فقط كمنصة. سيقوم الأمر تلقائيًا بـ:
   - استبدال `lib/firebase_options.dart` بالقيم الصحيحة.
   - تحميل `android/app/google-services.json` الحقيقي.

## الخطوة 3: رفع قواعد أمان Firestore

انسخ محتوى ملف `firestore.rules` الموجود في جذر المشروع، والصقه في:
Firebase Console ← Firestore Database ← Rules ← ثم اضغط Publish.

## الخطوة 4: إنشاء أول حساب مدير (Admin)

التطبيق لا يحتوي على شاشة "تسجيل" عامة (المدير فقط يضيف الخدام من داخل التطبيق)، لذلك يجب إنشاء أول حساب مدير يدويًا:

1. من Firebase Console ← Authentication ← Users ← Add user، أدخل بريدًا إلكترونيًا وكلمة مرور.
2. انسخ الـ **User UID** الخاص بالحساب الذي أنشأته.
3. من Firestore Database ← Start collection ← اسم المجموعة `users`.
4. أنشئ مستندًا (Document) جديدًا، اجعل **معرّف المستند (Document ID) هو نفس الـ UID** الذي نسخته، وأضف الحقول التالية:
   - `email` (string): نفس البريد الإلكتروني الذي استخدمته.
   - `name` (string): اسم المدير.
   - `role` (string): القيمة يجب أن تكون بالضبط `admin`.

الآن يمكنك تسجيل الدخول بهذا الحساب من التطبيق، وستظهر لك كل صلاحيات المدير، بما فيها إضافة بقية الخدام من شاشة الإعدادات ← إدارة الخدام (بدون الحاجة للرجوع لـ Firebase Console مرة أخرى).

## الخطوة 5: التشغيل

```bash
flutter run
```

## الخطوة 6 (اختياري): بناء نسخة APK للتوزيع

```bash
flutter build apk --release
```
سيكون الملف الناتج في: `build/app/outputs/flutter-apk/app-release.apk`

> ⚠️ ملاحظة: ملف `android/app/build.gradle.kts` يستخدم حاليًا توقيع debug للنسخة release لتسهيل أول تجربة تشغيل. قبل نشر التطبيق فعليًا للخدام، يُفضّل إنشاء keystore خاص بك وربطه (راجع توثيق Flutter الرسمي لـ "Build and release an Android app").

## هيكل المشروع

```
lib/
  core/            ثوابت، ثيم، دوال مساعدة (استخراج الاسم، روابط واتساب، التواريخ)
  models/          نماذج البيانات (الشاب، سجل الحضور، المستخدم) + Hive Adapters
  services/        التخزين المحلي (Hive)، Firebase Auth، Firestore، المزامنة، Excel، النسخ الاحتياطي
  providers/       إدارة الحالة (Provider) لكل من المصادقة، الشباب، الحضور، الإعدادات
  screens/         كل شاشات التطبيق مقسّمة حسب القسم (auth, home, students, attendance, statistics, settings)
  widgets/         عناصر واجهة قابلة لإعادة الاستخدام
  main.dart        نقطة الدخول وربط كل شيء معًا
  firebase_options.dart  إعدادات Firebase (يُستبدل تلقائيًا بواسطة flutterfire configure)
```

## آلية العمل بدون إنترنت (Offline First) وحل التعارضات

- كل عملية (إضافة/تعديل/حذف شاب، تسجيل حضور) تُحفظ فورًا في قاعدة بيانات محلية (Hive) بغض النظر عن وجود إنترنت، ويتم وضع علامة `needsSync = true` عليها.
- بمجرد توفر الإنترنت (تتم مراقبته تلقائيًا عبر `connectivity_plus`)، تقوم `SyncService` برفع كل العناصر المعلّقة إلى Firestore.
- في نفس الوقت تستمع `SyncService` لتغييرات Firestore اللحظية (Streams)، وتدمجها في قاعدة البيانات المحلية لتظهر فورًا عند بقية الخدام.
- عند حدوث تعارض (نفس السجل عُدّل محليًا وفي السحابة في نفس الوقت تقريبًا)، يُطبَّق مبدأ **Last Write Wins** بالاعتماد على حقل `updatedAt`: السجل الأحدث زمنيًا هو الذي يُعتمد، مع الحفاظ على عدم فقد أي تغيير لم يُرفع بعد.

## الصلاحيات

| الإجراء | مدير | خادم |
|---|---|---|
| تسجيل الحضور | ✅ | ✅ |
| مشاهدة البيانات والإحصائيات | ✅ | ✅ |
| إرسال رسائل واتساب | ✅ | ✅ |
| إضافة / تعديل / حذف شاب | ✅ | ❌ |
| إدارة الخدام | ✅ | ❌ |
| تصدير / استيراد Excel | ✅ | ❌ |
| النسخ الاحتياطي / الاستعادة | ✅ | ❌ |
| تعديل رسالة واتساب | ✅ | ❌ |

## ملاحظات إضافية

- التطبيق يدعم اللغة العربية بالكامل واتجاه RTL في كل الشاشات.
- الخط المستخدم هو "Cairo" عبر مكتبة `google_fonts` (يُحمَّل ويُخزَّن مؤقتًا تلقائيًا عند أول تشغيل متصل بالإنترنت).
- يمكنك تعديل قائمة الأنشطة من `lib/core/constants/app_constants.dart`.
