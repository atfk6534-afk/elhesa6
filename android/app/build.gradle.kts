plugins {
    id("com.android.application")
    id("kotlin-android")
    // يجب أن يأتي بلجن Flutter Gradle بعد بلجن Android و Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.lahan.attendance_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // مطلوب لدعم Java 8+ APIs (تستخدمها بعض مكتبات flutterfire) على Android القديم
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // معرّف التطبيق - يجب أن يطابق نفس المعرّف المسجل في Firebase Console
        applicationId = "com.lahan.attendance_app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // ⚠️ يجب استبدال هذا بتوقيع (signing config) خاص بك قبل النشر الفعلي على المتجر
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:33.4.0"))
}
