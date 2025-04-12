plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 允许插件添加自己的仓库
repositories {
    google()
    mavenCentral()
    maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
}

// 添加这段代码来解决"Cannot access output property"问题
gradle.taskGraph.whenReady {
    tasks.forEach { task ->
        if (task.name.contains("compileFlutterBuildDebug")) {
            task.doNotTrackState("Flutter build task state tracking disabled")
        }
    }
}

// 添加这段代码解决"dir is null"问题
tasks.withType<Copy>().configureEach {
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
    doFirst {
        source.forEach { 
            if (it is File && !it.exists()) {
                project.logger.warn("File or directory ${it.path} does not exist, but continuing anyway")
            }
        }
    }
}

android {
    namespace = "com.example.my_app"
    compileSdk = 35
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
        applicationId = "com.example.my_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // 启用所有优化，但保留调试信息
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // 禁用不必要的构建功能
    buildFeatures {
        buildConfig = true
    }
}

// 确保Flutter插件正确配置
flutter {
    source = "../.."
}
