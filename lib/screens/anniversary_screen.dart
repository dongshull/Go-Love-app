import 'package:flutter/material.dart';
import '../models/anniversary.dart';
import '../services/api_service.dart';
import '../widgets/add_anniversary_dialog.dart';
import '../widgets/edit_anniversary_dialog.dart';
import 'package:intl/intl.dart';
import '../utils/image_utils.dart';

class AnniversaryScreen extends StatefulWidget {
  const AnniversaryScreen({super.key});

  @override
  State<AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends State<AnniversaryScreen> {
  final _apiService = ApiService();
  List<Anniversary> _anniversaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('纪念日屏幕: 初始化');
    _loadAnniversaries();
  }

  Future<void> _loadAnniversaries() async {
    print('纪念日屏幕: 开始加载纪念日列表');
    setState(() {
      _isLoading = true;
    });

    try {
      final anniversaries = await _apiService.getAnniversaries();
      print('纪念日屏幕: 成功获取 ${anniversaries.length} 个纪念日');
      setState(() {
        _anniversaries = anniversaries;
        _isLoading = false;
      });
    } catch (e) {
      print('纪念日屏幕: 加载失败 - $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
    print('纪念日屏幕: 显示添加对话框');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddAnniversaryDialog(),
    );

    if (result == true) {
      print('纪念日屏幕: 添加成功，重新加载列表');
      _loadAnniversaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('纪念日屏幕: 构建界面');
    print('纪念日屏幕: 加载状态 - $_isLoading');
    print('纪念日屏幕: 纪念日数量 - ${_anniversaries.length}');

    return Scaffold(
      extendBody: true,
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _anniversaries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '还没有纪念日',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('添加纪念日'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnniversaries,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80, // 调整为更合适的底部间距
                ),
                itemCount: _anniversaries.length,
                itemBuilder: (context, index) {
                  final anniversary = _anniversaries[index];
                  return Dismissible(
                    key: Key(anniversary.id.toString()),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '编辑',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerRight,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '删除',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        // 删除操作需要确认
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: const Text('确定要删除这个纪念日吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // 编辑操作直接执行
                        _showEditDialog(anniversary);
                        return false;  // 不消失，只显示编辑对话框
                      }
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        _deleteAnniversary(anniversary);
                      }
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                    radius: 24,
                                    child: ImageUtils.isValidBase64Image(anniversary.avatar)
                                      ? ClipOval(
                                          child: ImageUtils.base64ToImage(
                                            anniversary.avatar,
                                            width: 48,
                                            height: 48,
                                            errorWidget: const Icon(Icons.person, color: Colors.white),
                                          ),
                                        )
                                      : (anniversary.avatar != null && anniversary.avatar!.startsWith('http'))
                                        ? ClipOval(
                                            child: Image.network(
                                              anniversary.avatar!,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.person, color: Colors.white),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          anniversary.name ?? '匿名用户',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.pink[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.pink[100]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.person_outline,
                                                size: 14,
                                                color: Colors.pink,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${anniversary.username ?? ''}  ID: ${anniversary.userId}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.pink[800],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.pink[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.pink[100]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  anniversary.content ?? '无内容',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMoodColor(anniversary.moodTag),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getMoodIcon(anniversary.moodTag),
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          anniversary.moodTag ?? '无心情',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '创建于：${DateFormat('yyyy-MM-dd HH:mm:ss').format(anniversary.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.transparent,
        elevation: 0,
        child: const SizedBox(height: 56),
      ),
    );
  }

  // 显示操作菜单
  void _showOptionsMenu(BuildContext context, Anniversary anniversary) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(anniversary);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showDeleteConfirmDialog(anniversary);
                  if (confirm == true) {
                    _deleteAnniversary(anniversary);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示编辑对话框
  Future<void> _showEditDialog(Anniversary anniversary) async {
    print('纪念日屏幕: 显示编辑对话框 - id: ${anniversary.id}');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditAnniversaryDialog(anniversary: anniversary),
    );

    if (result == true) {
      print('纪念日屏幕: 编辑成功，重新加载列表');
      _loadAnniversaries();
    }
  }

  // 显示删除确认对话框
  Future<bool?> _showDeleteConfirmDialog(Anniversary anniversary) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${anniversary.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 删除纪念日
  Future<void> _deleteAnniversary(Anniversary anniversary) async {
    print('纪念日屏幕: 开始删除纪念日 - id: ${anniversary.id}');
    try {
      await _apiService.deleteAnniversary(anniversary.id);
      print('纪念日屏幕: 删除成功，重新加载列表');
      _loadAnniversaries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    } catch (e) {
      print('纪念日屏幕: 删除失败 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }

  // 获取心情颜色
  Color _getMoodColor(String? moodTag) {
    switch (moodTag?.toLowerCase()) {
      case '开心':
        return Colors.green;
      case '快乐':
        return Colors.orange;
      case '幸福':
        return Colors.pink;
      case '感动':
        return Colors.purple;
      case '期待':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // 获取心情图标
  IconData _getMoodIcon(String? moodTag) {
    switch (moodTag?.toLowerCase()) {
      case '开心':
        return Icons.sentiment_very_satisfied;
      case '快乐':
        return Icons.sentiment_satisfied;
      case '幸福':
        return Icons.favorite;
      case '感动':
        return Icons.emoji_emotions;
      case '期待':
        return Icons.auto_awesome;
      default:
        return Icons.sentiment_neutral;
    }
  }
}