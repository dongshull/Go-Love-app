@echo off
echo 将项目移动到无空格路径以解决符号链接问题
set TARGET_DIR=C:\FlutterProjects\my_app

echo 创建目标目录 %TARGET_DIR%...
if not exist %TARGET_DIR% mkdir %TARGET_DIR%

echo 复制项目文件到 %TARGET_DIR%...
xcopy /E /I /H /Y /Q "X:\New APP\my_app\*" %TARGET_DIR%

echo 移动完成！现在您可以在命令提示符中使用以下命令打开新项目：
echo cd %TARGET_DIR%
echo 然后运行：
echo flutter run 