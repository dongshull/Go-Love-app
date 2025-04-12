import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AddAnniversaryDialog extends StatefulWidget {
  const AddAnniversaryDialog({super.key});

  @override
  State<AddAnniversaryDialog> createState() => _AddAnniversaryDialogState();
}

class _AddAnniversaryDialogState extends State<AddAnniversaryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedMoodTag;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加纪念日'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '请输入纪念日名称',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  hintText: '请输入纪念日内容',
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
              DropdownButtonFormField<String>(
                value: _selectedMoodTag,
                decoration: const InputDecoration(
                  labelText: '心情',
                  hintText: '请选择心情',
                ),
                items: const [
                  DropdownMenuItem(value: '开心', child: Text('开心')),
                  DropdownMenuItem(value: '快乐', child: Text('快乐')),
                  DropdownMenuItem(value: '幸福', child: Text('幸福')),
                  DropdownMenuItem(value: '感动', child: Text('感动')),
                  DropdownMenuItem(value: '期待', child: Text('期待')),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedMoodTag = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '日期',
                          border: const OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, color: Colors.pink[300]),
                        ),
                        child: Text(
                          DateFormat('yyyy年MM月dd日').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '时间',
                          border: const OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time, color: Colors.pink[300]),
                        ),
                        child: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final dateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                );

                await ApiService().createAnniversary(
                  name: _nameController.text,
                  content: _contentController.text,
                  moodTag: _selectedMoodTag,
                );
                
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('添加失败：$e')),
                  );
                }
              }
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
} 