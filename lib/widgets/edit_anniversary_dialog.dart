import 'package:flutter/material.dart';
import '../models/anniversary.dart';
import '../services/api_service.dart';

class EditAnniversaryDialog extends StatefulWidget {
  final Anniversary anniversary;

  const EditAnniversaryDialog({super.key, required this.anniversary});

  @override
  State<EditAnniversaryDialog> createState() => _EditAnniversaryDialogState();
}

class _EditAnniversaryDialogState extends State<EditAnniversaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late TextEditingController _moodTagController;
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.anniversary.name);
    _contentController = TextEditingController(text: widget.anniversary.content);
    _moodTagController = TextEditingController(text: widget.anniversary.moodTag);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _moodTagController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.updateAnniversary(
        id: widget.anniversary.id,
        name: _nameController.text,
        content: _contentController.text,
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
      title: const Text('编辑纪念日'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '纪念日名称',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入纪念日名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '纪念日内容',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入纪念日内容';
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