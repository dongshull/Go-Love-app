@echo off
setlocal

:: 设置环境变量
set FLUTTER_SYMLINK=false
set GRADLE_OPTS=-Dorg.gradle.daemon=false -Dorg.gradle.configureondemand=false -Dorg.gradle.jvmargs=-Xmx4G

:: 清理项目
echo Cleaning project...
call flutter clean

:: 获取依赖
echo Getting dependencies...
call flutter pub get --no-version-check

:: 尝试运行
echo Running app...
call flutter run --no-version-check --verbose

endlocal 