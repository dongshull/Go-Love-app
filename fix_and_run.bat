@echo off
setlocal

echo ===== 开始修复Flutter构建问题 =====

:: 设置环境变量
set FLUTTER_SYMLINK=false
set FLUTTER_SYMLINKS_TO_NATIVE_BUILD=false
set GRADLE_OPTS=-Dorg.gradle.daemon=false -Dorg.gradle.configureondemand=false -Dorg.gradle.jvmargs=-Xmx4G
set COPY_INSTEAD_OF_SYMLINK=true

:: 清理项目
echo.
echo 1. 清理项目...
call flutter clean

:: 清理Android构建
echo.
echo 2. 清理Android构建文件...
cd android
call gradlew clean --warning-mode=all
cd ..

:: 获取依赖
echo.
echo 3. 获取Flutter依赖...
call flutter pub get

:: 构建APK而不是直接运行
echo.
echo 4. 构建Android APK...
call flutter build apk --debug --no-tree-shake-icons

echo.
echo ====== 构建完成 ======
echo.
echo 如果构建成功，APK文件位于：build\app\outputs\flutter-apk\app-debug.apk
echo.
echo 您可以使用以下命令安装到设备：
echo adb install -r build\app\outputs\flutter-apk\app-debug.apk
echo.
echo 然后使用以下命令运行应用：
echo flutter run --use-application-binary=build\app\outputs\flutter-apk\app-debug.apk

:: 可选：自动安装
echo.
echo 是否要自动安装并运行？(Y/N)
set /p INSTALL_CHOICE=

if /i "%INSTALL_CHOICE%"=="Y" (
  echo.
  echo 安装APK到设备...
  call adb install -r build\app\outputs\flutter-apk\app-debug.apk
  
  echo.
  echo 运行应用...
  call flutter run --use-application-binary=build\app\outputs\flutter-apk\app-debug.apk
)

endlocal 