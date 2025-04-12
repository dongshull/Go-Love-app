import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/image_utils.dart';
import 'dashboard_screen.dart';
import 'anniversary_screen.dart';
import 'memory_screen.dart';
import 'whisper_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _apiService = ApiService();
  late final List<Widget> _screens;

  // 添加此方法允许外部设置页面索引
  void setPageIndex(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    print('HomeScreen 初始化');
    print('用户: \\${widget.user.username}');
    // 使用公开的 getter 方法
    print('Token 是否存在: \\${_apiService.hasToken}');
    print('ApiKey 是否存在: \\${_apiService.hasApiKey}');
    
    // 初始化页面列表并传递用户信息
    _screens = [
      DashboardScreen(
        user: widget.user,
        onNavigateToPage: setPageIndex, // 传递回调函数
      ),
      const AnniversaryScreen(),
      const MemoryScreen(),
      const WhisperScreen(),
      ProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 定义页面标题数组
    final List<String> pageTitles = [
      '首页',
      '纪念日',
      '美好回忆',
      '悄悄话',
      '${widget.user.username}的资料',
    ];
    
    return WillPopScope(
      // 防止用户意外按返回键退出应用
      onWillPop: () async {
        if (_selectedIndex != 0) {
          // 如果不在首页，则返回首页
          setState(() => _selectedIndex = 0);
          return false;
        }
        // 否则显示退出确认对话框
        return await _showExitConfirmDialog() ?? false;
      },
      child: Scaffold(
        extendBody: true, // 允许内容延伸到底部导航栏下方
        appBar: AppBar(
          title: Text(
            pageTitles[_selectedIndex],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // 添加头像到AppBar右侧
            GestureDetector(
              onTap: () => setPageIndex(4), // 点击头像跳转到个人页面
              child: Container(
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  child: ImageUtils.isValidBase64Image(widget.user.avatar)
                    ? ClipOval(
                        child: ImageUtils.base64ToImage(
                          widget.user.avatar,
                          width: 36,
                          height: 36,
                          errorWidget: const Icon(Icons.person, size: 18, color: Colors.white),
                        ),
                      )
                    : (widget.user.avatar != null && widget.user.avatar!.startsWith('http'))
                      ? ClipOval(
                          child: Image.network(
                            widget.user.avatar!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 18, color: Colors.white),
                          ),
                        )
                      : const Icon(Icons.person, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        body: _screens[_selectedIndex],
        // 底部导航栏调整
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), 
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex < 4 ? _selectedIndex : 0, // 确保索引在范围内
              onTap: setPageIndex,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              showUnselectedLabels: true,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 20,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded, size: 28),
                  label: '首页',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_rounded),
                  activeIcon: Icon(Icons.calendar_today_rounded, size: 28),
                  label: '纪念日',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.photo_album_rounded),
                  activeIcon: Icon(Icons.photo_album_rounded, size: 28),
                  label: '美好回忆',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_rounded),
                  activeIcon: Icon(Icons.chat_rounded, size: 28),
                  label: '悄悄话',
                ),
              ],
            ),
          ),
        ),
        // 底部填充，为悬浮按钮留出足够空间
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
  
  // 退出确认对话框
  Future<bool?> _showExitConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('您确定要退出应用吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 