import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    kotlin("android")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.logiflow"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.logiflow"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "2.0.1"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
        disable += "MissingTranslation"
    }
}

flutter {
    source = "../.."  
}

dependencies {
    implementation("io.flutter:flutter_embedding_release")
}
