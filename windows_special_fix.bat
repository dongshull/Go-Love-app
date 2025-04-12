@echo off
setlocal

echo === Windows特殊修复程序 - 解决路径空格问题 ===
echo.
echo 您的项目路径包含空格 (X:\New APP\my_app)，这会导致Flutter构建问题。
echo 此修复程序可以在不移动项目的情况下解决这个问题。
echo.

:: 创建不包含空格的符号链接
echo 1. 创建符号链接...
if not exist C:\FlutterTemp\ mkdir C:\FlutterTemp
if exist C:\FlutterTemp\my_app rmdir C:\FlutterTemp\my_app

:: 使用mklink而不是Flutter的符号链接系统
echo 创建符号链接至 C:\FlutterTemp\my_app...
if not exist "C:\FlutterTemp\my_app" (
  mklink /J "C:\FlutterTemp\my_app" "X:\New APP\my_app"
  if errorlevel 1 (
    echo 创建符号链接失败！请尝试以管理员身份运行此批处理文件。
    pause
    exit /b 1
  )
)

:: 设置环境变量
echo.
echo 2. 设置环境变量...
set FLUTTER_SYMLINK=false

:: 在新位置运行命令
echo.
echo 3. 切换到新位置...
cd /d C:\FlutterTemp\my_app

echo.
echo === 修复完成，现在可以在新位置构建项目 ===
echo 新项目位置: C:\FlutterTemp\my_app
echo.
echo 您可以运行以下命令构建并运行项目:
echo flutter clean
echo flutter pub get
echo flutter run
echo.
echo 是否立即运行这些命令？(Y/N)
set /p RUN_CHOICE=

if /i "%RUN_CHOICE%"=="Y" (
  echo.
  echo 清理项目...
  call flutter clean
  
  echo.
  echo 获取依赖...
  call flutter pub get
  
  echo.
  echo 运行项目...
  call flutter run
)

echo.
echo 请注意：请始终使用 C:\FlutterTemp\my_app 路径进行开发，而不是原始路径。
echo 所有更改会自动同步到原始位置。

endlocal 