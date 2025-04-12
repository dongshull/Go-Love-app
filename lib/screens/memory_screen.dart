import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../services/api_service.dart';
import '../widgets/add_memory_dialog.dart';
import '../widgets/edit_memory_dialog.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _apiService = ApiService();
  List<Memory> _memories = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    try {
      final memories = await _apiService.getMemories();
      setState(() {
        _memories = memories;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddMemoryDialog(),
    );

    if (result == true) {
      _loadMemories();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有回忆',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('添加回忆'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMemories,
      child: Scaffold(
        extendBody: true,
        body: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            left: 8,
            right: 8,
            top: 16,
            bottom: 100,
          ),
          itemCount: _memories.length,
          itemBuilder: (context, index) {
            final memory = _memories[index];
            return Dismissible(
              key: Key(memory.id.toString()),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                color: Colors.blue,
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  return await _showDeleteConfirmDialog(memory);
                } else if (direction == DismissDirection.startToEnd) {
                  _showEditDialog(memory);
                  return false;
                }
                return false;
              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  _deleteMemory(memory.id);
                }
              },
              child: GestureDetector(
                onLongPress: () {
                  _showOptionsMenu(context, memory);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        // 图片背景
                        Positioned.fill(
                          child: memory.image != null
                            ? _isBase64Image(memory.image!)
                              ? Builder(
                                  builder: (context) {
                                    final imageData = _decodeBase64Image(memory.image!);
                                    if (imageData != null) {
                                      return Image.memory(
                                        imageData,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Base64图片显示错误: $error');
                                          return _buildErrorContainer('Base64图片显示失败');
                                        },
                                      );
                                    } else {
                                      return _buildErrorContainer('Base64图片解码失败');
                                    }
                                  },
                                )
                              : Image.network(
                                  memory.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('网络图片显示错误: $error');
                                    return _buildErrorContainer('图片加载失败');
                                  },
                                )
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                        ),
                        // 模糊遮罩
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 内容
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 头像和标题行
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 头像
                                  if (memory.avatar != null)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(memory.avatar!),
                                      backgroundColor: Colors.grey[300],
                                    ),
                                  if (memory.avatar != null)
                                    const SizedBox(width: 12),
                                  // 标题
                                  Expanded(
                                    child: Text(
                                      memory.title ?? '无标题',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                memory.content ?? '无内容',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                memory.moodTag ?? '无心情标签',
                                style: TextStyle(
                                  color: Colors.pink[300],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '创建于：${DateFormat('yyyy-MM-dd HH:mm:ss').format(memory.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
      ),
    );
  }

  // 显示操作菜单
  void _showOptionsMenu(BuildContext context, Memory memory) {
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
                  _showEditDialog(memory);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showDeleteConfirmDialog(memory);
                  if (confirm == true) {
                    _deleteMemory(memory.id);
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
  Future<void> _showEditDialog(Memory memory) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditMemoryDialog(memory: memory),
    );

    if (result == true) {
      _loadMemories();
    }
  }

  // 显示删除确认对话框
  Future<bool?> _showDeleteConfirmDialog(Memory memory) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${memory.title}"吗？'),
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

  // 删除美好回忆
  Future<void> _deleteMemory(int id) async {
    try {
      await _apiService.deleteMemory(id);
      
      setState(() {
        _memories.removeWhere((item) => item.id == id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回忆已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.toString()}')),
        );
      }
    }
  }

  // 检查是否是Base64图片
  bool _isBase64Image(String image) {
    try {
      // 检查是否是data:image格式
      if (image.startsWith('data:image/')) {
        return true;
      }
      
      // 尝试解码，如果能成功解码则为Base64
      base64Decode(image);
      return true;
    } catch (e) {
      print('不是Base64图片: $e');
      return false;
    }
  }

  // 处理Base64图片数据
  Uint8List? _decodeBase64Image(String image) {
    try {
      if (image.startsWith('data:image/')) {
        // 处理data:image格式
        final parts = image.split(',');
        if (parts.length == 2) {
          return base64Decode(parts[1]);
        }
      } else {
        // 处理纯Base64字符串
        return base64Decode(image);
      }
    } catch (e) {
      print('Base64解码失败: $e');
    }
    return null;
  }

  // 构建错误显示容器
  Widget _buildErrorContainer(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}