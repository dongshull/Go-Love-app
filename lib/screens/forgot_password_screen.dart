import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialServerUrl;
  
  const ForgotPasswordScreen({super.key, this.initialServerUrl});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _serverController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialServerUrl != null) {
      _serverController.text = widget.initialServerUrl!;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  // 根据接口，发送重置密码请求
  // 注意：由于接口文档中没有明确的忘记密码接口，这里使用修改密码接口模拟
  // 实际项目中应当根据具体API实现
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 设置服务器地址
      _apiService.setBaseUrl(_serverController.text);
      
      // 调用重置密码API
      await _apiService.resetPassword(
        _usernameController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码重置请求已发送，请通过邮箱验证后登录')),
        );
        
        // 返回登录页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              initialUsername: _usernameController.text,
              initialServerUrl: _serverController.text,
            ),
          ),
        );
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink[100]!,
              Colors.purple[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '重置密码',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _serverController,
                      decoration: InputDecoration(
                        labelText: '服务器地址',
                        prefixIcon: const Icon(Icons.dns),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        hintText: '请输入完整的服务器地址',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入服务器地址';
                        }
                        // 简单验证服务器地址格式
                        if (!value.startsWith('http://') && !value.startsWith('https://')) {
                          return '服务器地址应以http://或https://开头';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: '用户名',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入用户名';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: '新密码',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureNewPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入新密码';
                        }
                        if (value.length < 6) {
                          return '密码长度至少为6位';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: '确认新密码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请确认新密码';
                        }
                        if (value != _newPasswordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                '重置密码',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '返回登录',
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 