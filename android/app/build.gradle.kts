plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.its19"
    compileSdk = flutter.compileSdkVersion
    // NDK versiyonu kaldırıldı - Flutter otomatik olarak uygun versiyonu kullanacak
       ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Core library desugaring - flutter_local_notifications için gerekli
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.its19"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // record_android paketi için minimum SDK versiyonu
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packagingOptions {
        pickFirst("**/classes.dex")
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
        exclude("META-INF/DEPENDENCIES")
        exclude("META-INF/LICENSE")
        exclude("META-INF/LICENSE.txt")
        exclude("META-INF/license.txt")
        exclude("META-INF/NOTICE")
        exclude("META-INF/NOTICE.txt")
        exclude("META-INF/notice.txt")
        exclude("META-INF/ASL2.0")
        exclude("META-INF/*.kotlin_module")
        exclude("META-INF/INDEX.LIST")
        exclude("META-INF/io.netty.versions.properties")
    }
    
    lint {
        disable.add("InvalidPackage")
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    // Core library desugaring - flutter_local_notifications için gerekli (min 2.1.4)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

configurations.all {
    resolutionStrategy {
        force("androidx.annotation:annotation-experimental:1.3.0")
    }
}

// Java 8 uyarılarını bastır (eski Flutter plugin'leri Java 8 kullanıyor)
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-options")
}
