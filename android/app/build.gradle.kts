plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.GradleException

val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties()
if (keyPropsFile.isFile) {
    FileInputStream(keyPropsFile).use(keyProps::load)
}

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val signingPropertyNames = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingSigningProperties = signingPropertyNames.filter {
    keyProps.getProperty(it).isNullOrBlank()
}
val releaseStoreFile = keyProps.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { storeFilePath ->
        if (storeFilePath.contains("/") || storeFilePath.contains("\\")) {
            rootProject.file(storeFilePath)
        } else {
            file(storeFilePath)
        }
    }
val hasReleaseSigning = keyPropsFile.isFile &&
    missingSigningProperties.isEmpty() &&
    releaseStoreFile?.isFile == true

if (releaseTaskRequested && !hasReleaseSigning) {
    val reasons = buildList {
        if (!keyPropsFile.isFile) add("android/key.properties is missing")
        if (missingSigningProperties.isNotEmpty()) {
            add("missing properties: ${missingSigningProperties.joinToString()}")
        }
        if (releaseStoreFile != null && !releaseStoreFile.isFile) {
            add("keystore does not exist: ${releaseStoreFile.path}")
        }
    }
    throw GradleException("Release signing is not configured (${reasons.joinToString("; ")}).")
}

android {
    namespace = "com.innocentree.pumpingday"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.innocentree.pumpingday"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
