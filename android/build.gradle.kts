plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // >>> HATA ÇÖZÜMÜ İÇİN EKLENDİ (1/2) <<<
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_application_1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Android 5.0+ support for better compatibility
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // MultiDex support for larger apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")

    // >>> HATA ÇÖZÜMÜ İÇİN EKLENDİ (2/2) <<<
    // Core Library Desugaring kütüphanesi
    coreLibraryDesugaring("com.android.tools:desugar-jdk-libs:2.0.0")
    
    // Firebase BOM - tüm Firebase paketlerinin versiyonlarını yönetir
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    
    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
    
    // Firebase Authentication
    implementation("com.google.firebase:firebase-auth")
    
    // Cloud Firestore
    implementation("com.google.firebase:firebase-firestore")
    
    // Firebase Storage
    implementation("com.google.firebase:firebase-storage")
}

flutter {
    source = "../.."
}