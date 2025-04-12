pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

// 添加明确的根项目路径
rootProject.projectDir = file(".")

// 让 Gradle 解析相对路径
gradle.beforeProject {
    if (rootProject.projectDir.absolutePath.contains(" ")) {
        logger.warn("Your project path contains spaces: ${rootProject.projectDir.absolutePath}")
        logger.warn("This may cause problems with Flutter build system.")
    }
}

// 关键修改：不强制使用settings中的仓库配置
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // 允许插件添加自己的仓库
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("https://repo.maven.apache.org/maven2/") }
    }
}

// Include the host app project.
include(":app")

// Flutter对路径的引用已经在Flutter插件中处理
