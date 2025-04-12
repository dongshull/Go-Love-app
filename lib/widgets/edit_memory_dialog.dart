import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/memory.dart';
import '../services/api_service.dart';
import 'dart:convert';

class EditMemoryDialog extends StatefulWidget {
  final Memory memory;

  const EditMemoryDialog({super.key, required this.memory});

  @override
  State<EditMemoryDialog> createState() => _EditMemoryDialogState();
}

class _EditMemoryDialogState extends State<EditMemoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _moodTagController;
  final _apiService = ApiService();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memory.title);
    _contentController = TextEditingController(text: widget.memory.content);
    _moodTagController = TextEditingController(text: widget.memory.moodTag);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _moodTagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageData;
      if (_imageFile != null) {
        // 读取新选择的图片并转换为Base64
        final bytes = await _imageFile!.readAsBytes();
        final base64Image = base64Encode(bytes);
        imageData = 'data:image/jpeg;base64,$base64Image';
      }

      await _apiService.updateMemory(
        id: widget.memory.id,
        avatar: widget.memory.avatar,
        title: _titleController.text,
        content: _contentController.text,
        image: imageData ?? widget.memory.image,  // 使用新图片或保持原图片
        moodTag: _moodTagController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑回忆'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _moodTagController,
                decoration: const InputDecoration(
                  labelText: '心情标签',
                  prefixIcon: Icon(Icons.mood),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入心情标签';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        )
                      : widget.memory.image != null
                          ? Image.network(
                              widget.memory.image!,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40),
                                  Text('点击更换图片'),
                                ],
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
} 