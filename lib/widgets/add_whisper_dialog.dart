import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddWhisperDialog extends StatefulWidget {
  const AddWhisperDialog({super.key});

  @override
  State<AddWhisperDialog> createState() => _AddWhisperDialogState();
}

class _AddWhisperDialogState extends State<AddWhisperDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.createWhisper(
        avatar: 'https://api.dicebear.com/7.x/thumbs/svg?seed=${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        content: _contentController.text,
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
      title: const Text('添加悄悄话'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '悄悄话名称',
                  prefixIcon: Icon(Icons.chat),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入悄悄话名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '悄悄话内容',
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入悄悄话内容';
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
              : const Text('添加'),
        ),
      ],
    );
  }
} 