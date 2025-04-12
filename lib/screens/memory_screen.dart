import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../services/api_service.dart';
import '../widgets/add_memory_dialog.dart';
import '../widgets/edit_memory_dialog.dart';
import '../utils/image_utils.dart';
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
        backgroundColor: Colors.grey[100],
        body: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
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
                color: Colors.red[100],
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                color: Colors.blue[100],
                child: const Icon(Icons.edit, color: Colors.blue),
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
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头部信息
                    if (memory.image != null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // 头像
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[200],
                                child: memory.avatar != null
                                  ? ImageUtils.isValidBase64Image(memory.avatar)
                                    ? ClipOval(
                                        child: ImageUtils.base64ToImage(
                                          memory.avatar,
                                          width: 40,
                                          height: 40,
                                          errorWidget: const Icon(Icons.person, color: Colors.white),
                                        ),
                                      )
                                    : ClipOval(
                                        child: Image.network(
                                          memory.avatar!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              // 标题和时间
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          memory.title ?? '无标题',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MM月dd日 HH:mm').format(memory.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 更多操作按钮
                              IconButton(
                                icon: const Icon(Icons.more_horiz, color: Colors.white),
                                onPressed: () => _showOptionsMenu(context, memory),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // 头像
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              child: memory.avatar != null
                                ? ImageUtils.isValidBase64Image(memory.avatar)
                                  ? ClipOval(
                                      child: ImageUtils.base64ToImage(
                                        memory.avatar,
                                        width: 40,
                                        height: 40,
                                        errorWidget: const Icon(Icons.person, color: Colors.white),
                                      ),
                                    )
                                  : ClipOval(
                                      child: Image.network(
                                        memory.avatar!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            // 标题和时间
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        memory.title ?? '无标题',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '${memory.username ?? '未知用户'} · ID: ${memory.userId}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MM月dd日 HH:mm').format(memory.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 更多操作按钮
                            IconButton(
                              icon: const Icon(Icons.more_horiz),
                              onPressed: () => _showOptionsMenu(context, memory),
                            ),
                          ],
                        ),
                      ),
                    // 内容
                    if (memory.content != null && memory.content!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          memory.content!,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    // 图片
                    if (memory.image != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _isBase64Image(memory.image!)
                            ? Image.memory(
                                base64Decode(memory.image!.split(',').last),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error_outline),
                                  ),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: memory.image!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error_outline),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    // 底部信息
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 心情标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mood,
                                  size: 16,
                                  color: Colors.pink[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  memory.moodTag ?? '无心情',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.pink[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // 编辑按钮
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditDialog(memory),
                            color: Colors.grey[600],
                            iconSize: 20,
                          ),
                          // 删除按钮
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirm = await _showDeleteConfirmDialog(memory);
                              if (confirm == true) {
                                _deleteMemory(memory.id);
                              }
                            },
                            color: Colors.grey[600],
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
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
          color: Colors.transparent,
          elevation: 0,
          height: 60,
          padding: const EdgeInsets.only(bottom: 8),
          child: const SizedBox(),
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
      if (image.startsWith('data:image/')) {
        return true;
      }
      base64Decode(image);
      return true;
    } catch (e) {
      return false;
    }
  }
}