import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/image_utils.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  bool _isUpdatingAvatar = false;

  void _logout() {
    // 清除 token 和 apiKey
    _apiService.setToken('');
    _apiService.setApiKey('');

    // 返回登录页面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
  
  // 上传头像
  Future<void> _uploadAvatar() async {
    try {
      setState(() {
        _isUpdatingAvatar = true;
      });
      
      // 使用工具类选择图片并转为Base64
      final base64Image = await ImageUtils.pickImageAsBase64(
        imageQuality: 70, // 降低图片质量以减小大小
        maxWidth: 500,    // 限制宽度
        maxHeight: 500,   // 限制高度
      );
      
      if (base64Image == null) {
        setState(() {
          _isUpdatingAvatar = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未选择图片或图片处理失败')),
          );
        }
        return;
      }
      
      print('选择的图片Base64长度: ${base64Image.length}');
      
      // 调用API更新头像
      try {
        final updatedAvatar = await _apiService.updateAvatar(base64Image);
        
        // 更新本地用户对象
        setState(() {
          widget.user.avatar = updatedAvatar;
          _isUpdatingAvatar = false;
        });
        
        if (widget.user.avatar != null) {
          print('头像更新成功: ${widget.user.avatar!.length > 50 ? widget.user.avatar!.substring(0, 50) + "..." : widget.user.avatar}');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('头像更新成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('API调用失败: $e');
        setState(() {
          _isUpdatingAvatar = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('头像更新失败: ${e.toString().split(":").last.trim()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('图片选择过程发生错误: $e');
      setState(() {
        _isUpdatingAvatar = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片选择失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 0, // 移除顶部间距
          bottom: 100, // 增加底部间距，确保内容不被导航栏遮挡
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16), // 添加顶部间距
            // 个人信息卡片
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 头像 - 使用GestureDetector以便点击更换头像
                    GestureDetector(
                      onTap: _isUpdatingAvatar ? null : _uploadAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.pink[100],
                            child: _isUpdatingAvatar
                                ? const CircularProgressIndicator(color: Colors.white)
                                : ImageUtils.isValidBase64Image(widget.user.avatar)
                                  ? ClipOval(
                                      child: ImageUtils.base64ToImage(
                                        widget.user.avatar,
                                        width: 80,
                                        height: 80,
                                        errorWidget: const Icon(Icons.person, size: 40, color: Colors.white),
                                      ),
                                    )
                                  : (widget.user.avatar != null && widget.user.avatar!.startsWith('http'))
                                    ? ClipOval(
                                        child: Image.network(
                                          widget.user.avatar!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          // 编辑图标
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 用户信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 用户名和ID
                          Row(
                            children: [
                              Text(
                                widget.user.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.pink[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ID: ${widget.user.id}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.pink[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          // 创建时间和最后更新
                          Row(
                            children: [
                              Icon(Icons.date_range, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 2),
                              Text(
                                '创建于: ${_formatDate(widget.user.createdAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout, color: Colors.red, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: '退出登录',
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.update, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 2),
                              Text(
                                '更新于: ${_formatDate(widget.user.updatedAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 账号设置卡片
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: Colors.pink),
                        const SizedBox(width: 8),
                        const Text(
                          '账号设置',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildSettingItem(
                    icon: Icons.edit,
                    title: '编辑个人资料',
                    subtitle: '修改头像、昵称等个人信息',
                    onTap: () {
                      // 跳转到编辑个人资料页面
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('即将开放，敬请期待')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.lock,
                    title: '修改密码',
                    subtitle: '定期更改密码可以提高账号安全性',
                    onTap: () {
                      // 跳转到修改密码页面
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('即将开放，敬请期待')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 通用设置卡片
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, color: Colors.pink),
                        const SizedBox(width: 8),
                        const Text(
                          '通用设置',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: '通知设置',
                    subtitle: '管理应用推送和提醒',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('即将开放，敬请期待')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.privacy_tip,
                    title: '隐私设置',
                    subtitle: '管理您的隐私和数据',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('即将开放，敬请期待')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.color_lens,
                    title: '主题设置',
                    subtitle: '自定义应用外观',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('即将开放，敬请期待')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.language,
                    title: '语言设置',
                    subtitle: '切换应用语言',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('简体中文', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('即将开放，敬请期待')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 帮助与支持卡片
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, color: Colors.pink),
                        const SizedBox(width: 8),
                        const Text(
                          '帮助与支持',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildSettingItem(
                    icon: Icons.question_answer,
                    title: '常见问题',
                    subtitle: '查看常见问题解答',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('即将开放，敬请期待')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.feedback,
                    title: '意见反馈',
                    subtitle: '帮助我们改进应用',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('即将开放，敬请期待')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.system_update,
                    title: '检查更新',
                    subtitle: '当前版本 1.0.0',
                    onTap: () {
                      _checkForUpdates();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: '关于爱迹',
                    subtitle: '版本 1.0.0',
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 新增的设置项构建方法
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
  
  // 关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.pink),
            SizedBox(width: 8),
            Text('关于爱迹'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '爱迹 V1.0.0',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '爱迹是一款专为情侣设计的轨迹记录应用，帮助您记录与爱人共同的美好时光。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('© 2023 爱迹团队 保留所有权利'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // 打开用户协议
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('即将开放，敬请期待')),
                );
              },
              child: const Text(
                '用户协议',
                style: TextStyle(
                  color: Colors.pink,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                // 打开隐私政策
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('即将开放，敬请期待')),
                );
              },
              child: const Text(
                '隐私政策',
                style: TextStyle(
                  color: Colors.pink,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 检查更新方法
  void _checkForUpdates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.pink),
            SizedBox(width: 8),
            Text('检查更新'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示加载指示器
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                  ),
                  const SizedBox(height: 16),
                  const Text('正在检查更新...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 模拟检查更新过程
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // 关闭加载对话框
      
      // 显示结果对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('已是最新版本'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('您当前使用的 1.0.0 版本已经是最新版本。'),
              SizedBox(height: 8),
              Text('我们会定期推出新功能，请保持关注！', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    });
  }
}
