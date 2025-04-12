@echo off
echo 禁用符号链接并构建APK
set FLUTTER_SYMLINK=false
set FLUTTER_SYMLINKS_TO_NATIVE_BUILD=false
set GRADLE_OPTS=-Dorg.gradle.daemon=false -Dorg.gradle.configureondemand=false

echo 清理项目...
flutter clean

echo 获取依赖...
flutter pub get --no-version-check

echo 构建APK...
flutter build apk

echo APK构建完成，位于 build\app\outputs\flutter-apk\app-release.apk

echo 请使用以下命令在设备上安装APK：
echo adb install build\app\outputs\flutter-apk\app-release.apk 