import 'package:flutter/material.dart';
import '../models/whisper.dart';
import '../services/api_service.dart';
import '../widgets/add_whisper_dialog.dart';
import '../widgets/edit_whisper_dialog.dart';
import 'package:intl/intl.dart';
import '../utils/image_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> {
  final _apiService = ApiService();
  List<Whisper> _whispers = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadWhispers();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId');
    });
  }

  Future<void> _loadWhispers() async {
    try {
      final whispers = await _apiService.getWhispers();
      setState(() {
        _whispers = whispers;
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
      builder: (context) => const AddWhisperDialog(),
    );

    if (result == true) {
      _loadWhispers();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_whispers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有悄悄话',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('发送悄悄话'),
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
      onRefresh: _loadWhispers,
      child: Scaffold(
        extendBody: true,
        body: ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 80,
          ),
          itemCount: _whispers.length,
          itemBuilder: (context, index) {
            final whisper = _whispers[index];
            final isCurrentUser = whisper.userId == _currentUserId;

            return Dismissible(
              key: Key(whisper.id.toString()),
              background: isCurrentUser ? Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red[100],
                child: const Icon(Icons.delete, color: Colors.red),
              ) : null,
              secondaryBackground: isCurrentUser ? Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                color: Colors.blue[100],
                child: const Icon(Icons.edit, color: Colors.blue),
              ) : null,
              direction: isCurrentUser ? DismissDirection.horizontal : DismissDirection.none,
              confirmDismiss: (direction) async {
                if (!isCurrentUser) return false;
                if (direction == DismissDirection.endToStart) {
                  return await _showDeleteConfirmDialog(whisper);
                } else if (direction == DismissDirection.startToEnd) {
                  _showEditDialog(whisper);
                  return false;
                }
                return false;
              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  _deleteWhisper(whisper.id);
                }
              },
              child: Align(
                alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCurrentUser) ...[
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              radius: 16,
                              child: ImageUtils.isValidBase64Image(whisper.avatar)
                                ? ClipOval(
                                    child: ImageUtils.base64ToImage(
                                      whisper.avatar,
                                      width: 32,
                                      height: 32,
                                      errorWidget: const Icon(Icons.person, size: 16, color: Colors.white),
                                    ),
                                  )
                                : (whisper.avatar != null && whisper.avatar!.startsWith('http'))
                                  ? ClipOval(
                                      child: Image.network(
                                        whisper.avatar!,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 16, color: Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.pink[100] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  whisper.content ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isCurrentUser ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              radius: 16,
                              child: ImageUtils.isValidBase64Image(whisper.avatar)
                                ? ClipOval(
                                    child: ImageUtils.base64ToImage(
                                      whisper.avatar,
                                      width: 32,
                                      height: 32,
                                      errorWidget: const Icon(Icons.person, size: 16, color: Colors.white),
                                    ),
                                  )
                                : (whisper.avatar != null && whisper.avatar!.startsWith('http'))
                                  ? ClipOval(
                                      child: Image.network(
                                        whisper.avatar!,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 16, color: Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MM-dd HH:mm').format(whisper.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
  void _showOptionsMenu(BuildContext context, Whisper whisper) {
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
                  _showEditDialog(whisper);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showDeleteConfirmDialog(whisper);
                  if (confirm == true) {
                    _deleteWhisper(whisper.id);
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
  Future<void> _showEditDialog(Whisper whisper) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditWhisperDialog(whisper: whisper),
    );

    if (result == true) {
      _loadWhispers();
    }
  }

  // 显示删除确认对话框
  Future<bool?> _showDeleteConfirmDialog(Whisper whisper) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('确定要删除这条悄悄话吗？'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                whisper.content ?? '无内容',
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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

  // 删除悄悄话
  Future<void> _deleteWhisper(int id) async {
    try {
      await _apiService.deleteWhisper(id);
      
      setState(() {
        _whispers.removeWhere((item) => item.id == id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('悄悄话已删除')),
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
}