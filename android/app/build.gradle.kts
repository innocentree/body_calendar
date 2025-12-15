plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.example.body_calendar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.body_calendar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystoreFile = file("upload-keystore.jks") // Ensure this file exists
            if (keystoreFile.exists()) {
                 storeFile = keystoreFile
                 // Load key.properties if it exists, otherwise use env vars (useful for CI if passing envs)
                 // But for this setup, we will rely on creating key.properties in CI or having it locally.
                 val keyPropsFile = rootProject.file("key.properties")
                 if (keyPropsFile.exists()) {
                     val p = Properties()
                     p.load(FileInputStream(keyPropsFile))
                     storePassword = p.getProperty("storePassword")
                     keyAlias = p.getProperty("keyAlias")
                     keyPassword = p.getProperty("keyPassword")
                 } else {
                     // Fallback to environment variables or throw error
                     storePassword = System.getenv("KEY_STORE_PASSWORD")
                     keyAlias = System.getenv("KEY_ALIAS")
                     keyPassword = System.getenv("KEY_PASSWORD")
                 }
            } else {
                println("Release keystore not found, skipping signing configuration")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
