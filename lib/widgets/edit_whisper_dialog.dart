import 'package:flutter/material.dart';
import '../models/whisper.dart';
import '../services/api_service.dart';

class EditWhisperDialog extends StatefulWidget {
  final Whisper whisper;

  const EditWhisperDialog({super.key, required this.whisper});

  @override
  State<EditWhisperDialog> createState() => _EditWhisperDialogState();
}

class _EditWhisperDialogState extends State<EditWhisperDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.whisper.name);
    _contentController = TextEditingController(text: widget.whisper.content);
  }

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
      await _apiService.updateWhisper(
        id: widget.whisper.id,
        avatar: widget.whisper.avatar,
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
      title: const Text('编辑悄悄话'),
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
              : const Text('保存'),
        ),
      ],
    );
  }
} 