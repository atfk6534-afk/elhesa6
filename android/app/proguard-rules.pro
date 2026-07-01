# قواعد إضافية للحفاظ على عمل Firebase وHive بعد تصغير الكود (R8/Proguard)
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class hive.** { *; }
-dontwarn com.google.firebase.**
