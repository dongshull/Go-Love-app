@echo off
echo 禁用符号链接并使用直接复制
set FLUTTER_SYMLINK=false
set FLUTTER_SYMLINKS_TO_NATIVE_BUILD=false
set GRADLE_OPTS=-Dorg.gradle.daemon=false -Dorg.gradle.configureondemand=false
set COPY_INSTEAD_OF_SYMLINK=true

echo 选择设备...
flutter devices

echo 选择一个设备（输入设备ID）：
set /p deviceid=

echo 正在运行应用到设备 %deviceid%...
flutter run -d %deviceid% --use-application-binary 