import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialUsername;
  final String? initialServerUrl;
  
  const LoginScreen({super.key, this.initialUsername, this.initialServerUrl});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  // 使用静态变量保存输入内容，防止重建时丢失
  static final _usernameController = TextEditingController();
  static final _passwordController = TextEditingController();
  static final _serverController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  static bool _rememberPassword = false;
  bool _obscurePassword = true;
  int _loginButtonClickCount = 0;
  List<Map<String, dynamic>> _loginHistory = [];
  
  // 数据库连接状态
  bool _isCheckingDbStatus = false;
  bool _isDbConnected = false;
  String _dbStatusMessage = '未检测';
  
  // 添加焦点节点以便更好地控制键盘
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _serverFocus = FocusNode();
  
  // 保存当前输入值以防止丢失
  static String _currentUsername = '';
  static String _currentPassword = '';
  static String _currentServer = '';
  
  // 添加防抖机制，避免频繁调用setState
  DateTime _lastSetState = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 防止键盘引起的UI闪烁
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    // 初始赋值，确保不会丢失之前的输入
    if (_currentUsername.isEmpty && widget.initialUsername != null) {
      _usernameController.text = widget.initialUsername!;
      _currentUsername = widget.initialUsername!;
    } else if (_currentUsername.isNotEmpty) {
      _usernameController.text = _currentUsername;
    }
    
    if (_currentServer.isEmpty && widget.initialServerUrl != null) {
      _serverController.text = widget.initialServerUrl!;
      _currentServer = widget.initialServerUrl!;
    } else if (_currentServer.isNotEmpty) {
      _serverController.text = _currentServer;
    }
    
    if (_currentPassword.isNotEmpty) {
      _passwordController.text = _currentPassword;
    }
    
    // 添加文本变化监听器，但使用addListener而不是onChanged
    // 这样可以避免在每次按键都触发setState
    _usernameController.addListener(_saveUsernameValue);
    _passwordController.addListener(_savePasswordValue);
    _serverController.addListener(_saveServerValue);
    
    // 初始化历史记录和服务器状态
    // 使用Future.microtask确保在UI渲染后执行这些操作
    Future.microtask(() async {
      await _loadLoginHistory();
      
      // 如果服务器地址为空，预先加载最后使用的服务器地址
      if (_serverController.text.isEmpty) {
        await _preloadServerUrl();
      }
      
      // 检查数据库连接状态
      await _checkDbStatus();
    });
  }
  
  // 使用单独的方法保存值，避免在UI线程中频繁调用setState
  void _saveUsernameValue() {
    _currentUsername = _usernameController.text;
  }
  
  void _savePasswordValue() {
    _currentPassword = _passwordController.text;
  }
  
  void _saveServerValue() {
    _currentServer = _serverController.text;
  }
  
  // 防抖setState，避免频繁重建
  void _safeSetState(VoidCallback fn) {
    if (DateTime.now().difference(_lastSetState).inMilliseconds > 300) {
      if (mounted) {
        setState(fn);
        _lastSetState = DateTime.now();
      }
    }
  }
  
  // 预加载最后使用的服务器地址
  Future<void> _preloadServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastServerUrl = prefs.getString('last_server_url');
      if (lastServerUrl != null && lastServerUrl.isNotEmpty && _serverController.text.isEmpty) {
        _serverController.text = lastServerUrl;
        _currentServer = lastServerUrl;
      }
    } catch (e) {
      print('加载服务器地址出错: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用从后台恢复或界面重新构建时，恢复输入值
    if (state == AppLifecycleState.resumed || state == AppLifecycleState.inactive) {
      _restoreInputValues();
    }
  }
  
  // 恢复输入值的方法
  void _restoreInputValues() {
    if (_usernameController.text != _currentUsername && _currentUsername.isNotEmpty) {
      _usernameController.text = _currentUsername;
    }
    if (_passwordController.text != _currentPassword && _currentPassword.isNotEmpty) {
      _passwordController.text = _currentPassword;
    }
    if (_serverController.text != _currentServer && _currentServer.isNotEmpty) {
      _serverController.text = _currentServer;
    }
  }
  
  Future<void> _loadLoginHistory() async {
    try {
      print('开始加载登录历史记录');
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('login_history');
      print('从SharedPreferences加载的历史记录JSON: ${historyJson?.substring(0, historyJson.length > 100 ? 100 : historyJson.length) ?? "null"}');
      
      if (historyJson != null && historyJson.isNotEmpty) {
        final decoded = json.decode(historyJson);
        setState(() {
          _loginHistory = List<Map<String, dynamic>>.from(
            decoded.map((x) => Map<String, dynamic>.from(x))
          );
        });
        print('成功加载${_loginHistory.length}条登录历史记录');
      } else {
        print('没有找到历史记录或历史记录为空');
      }
    } catch (e) {
      print('加载登录历史出错: $e');
      // 确保即使出错也把_loginHistory初始化为空列表
      setState(() {
        _loginHistory = [];
      });
    }
  }
  
  Future<void> _saveLoginHistory(String username, String serverUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 添加新的登录记录到历史列表
      final now = DateTime.now();
      final loginRecord = {
        'username': username,
        'server': serverUrl,
        'timestamp': now.toIso8601String(),
        'formattedTime': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
      };
      
      // 如果选择记住密码，则保存密码
      if (_rememberPassword) {
        loginRecord['password'] = _passwordController.text;
      }
      
      // 检查是否已存在相同的用户名和服务器记录，如果存在则更新时间
      int existingIndex = _loginHistory.indexWhere(
        (record) => record['username'] == username && record['server'] == serverUrl
      );
      
      if (existingIndex != -1) {
        // 保留原有密码，除非选择记住密码
        if (!_rememberPassword && _loginHistory[existingIndex].containsKey('password')) {
          loginRecord['password'] = _loginHistory[existingIndex]['password'];
        }
        _loginHistory[existingIndex] = loginRecord;
      } else {
        _loginHistory.insert(0, loginRecord); // 在列表开头添加新记录
      }
      
      // 限制历史记录最多保存10条
      if (_loginHistory.length > 10) {
        _loginHistory = _loginHistory.sublist(0, 10);
      }
      
      // 保存到SharedPreferences
      await prefs.setString('login_history', json.encode(_loginHistory));
      print('保存登录历史成功: ${_loginHistory.length}条记录');
      
      // 额外保存最后使用的服务器地址
      await prefs.setString('last_server_url', serverUrl);
    } catch (e) {
      print('保存登录历史出错: $e');
    }
  }

  @override
  void dispose() {
    // 不要在dispose中清除静态变量的内容
    // 仅释放监听器和焦点节点等资源
    _usernameController.removeListener(_saveUsernameValue);
    _passwordController.removeListener(_savePasswordValue);
    _serverController.removeListener(_saveServerValue);
    
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _serverFocus.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _login() async {
    // 再次确保当前值被保存
    _currentUsername = _usernameController.text;
    _currentPassword = _passwordController.text;
    _currentServer = _serverController.text;
    
    // 确保焦点从输入框移开，防止键盘引起的重建问题
    FocusScope.of(context).unfocus();
    
    // 如果正在加载，不允许重复点击
    if (_isLoading) return;
    
    // 增加点击计数，但只用于空输入框的情况
    if (_currentUsername.trim().isEmpty && 
        _currentPassword.trim().isEmpty &&
        _currentServer.trim().isEmpty) {
      _safeSetState(() {
        _loginButtonClickCount++;
      });
      
      // 如果点击了5次，显示历史记录
      if (_loginButtonClickCount == 5) {
        _showLoginHistoryDialog();
        return;
      }
    } else {
      // 有输入内容时重置计数器
      _loginButtonClickCount = 0;
    }
    
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save(); // 确保所有值都被保存

    _safeSetState(() => _isLoading = true);
    
    // 添加定时器，2秒后自动重置加载状态，允许用户再次点击登录按钮
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _safeSetState(() => _isLoading = false);
      }
    });

    try {
      // 设置服务器地址
      _apiService.setBaseUrl(_currentServer);
      
      final result = await _apiService.login(
        _currentUsername,
        _currentPassword,
      );

      // 登录成功，保存登录记录
      _saveLoginHistory(_currentUsername, _currentServer);
      
      print('登录结果: ${result}');
      print('用户数据: ${result['user']}');
      
      if (mounted) {
        print('准备导航到 HomeScreen');
        final userData = result['user'];
        final user = User.fromJson(userData);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: user),
          ),
        );
        print('已执行导航操作');
      }
    } catch (e) {
      print('登录异常: ${e}');
      if (mounted) {
        // 在对话框中显示更详细的错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: ${e.toString().split(":").last.trim()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    // 移除finally块，因为我们已经使用定时器来重置状态
  }
  
  void _showLoginHistoryDialog() {
    print('显示登录历史对话框，历史记录数量: ${_loginHistory.length}');
    
    // 无论如何都重置点击计数器
    setState(() {
      _loginButtonClickCount = 0;
    });
    
    // 如果历史记录为空，先尝试重新加载
    if (_loginHistory.isEmpty) {
      _loadLoginHistory().then((_) {
        print('重新加载历史记录完成，数量: ${_loginHistory.length}');
        _showHistoryDialogContent();
      });
    } else {
      _showHistoryDialogContent();
    }
  }
  
  // 实际显示历史对话框内容的方法
  void _showHistoryDialogContent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.pink),
            const SizedBox(width: 8),
            const Text('登录历史记录'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.4, // 限制最大高度
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  '点击记录可快速填充登录信息，长按可编辑',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                child: _loginHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('暂无登录记录'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _loginHistory.length,
                        itemBuilder: (context, index) {
                          final record = _loginHistory[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.account_circle, color: Colors.pink),
                              title: Text(
                                record['username'] ?? '未知用户',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '服务器: ${record['server'] ?? '未知服务器'}',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '登录时间: ${record['formattedTime'] ?? '未知时间'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // 选择历史记录
                                _usernameController.text = record['username'] ?? '';
                                _serverController.text = record['server'] ?? '';
                                
                                // 如果有保存密码，则填充密码
                                if (record.containsKey('password') && record['password'] != null) {
                                  _passwordController.text = record['password'];
                                  // 自动登录
                                  Navigator.pop(context);
                                  setState(() {
                                    _loginButtonClickCount = 0; // 重置计数器
                                  });
                                  _login();
                                } else {
                                  // 没有保存密码，需要用户手动输入
                                  Navigator.pop(context);
                                  setState(() {
                                    _loginButtonClickCount = 0; // 重置计数器
                                  });
                                  
                                  // 提示用户填写密码
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('请输入密码以完成登录'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () {
                                // 长按显示编辑对话框
                                _showEditHistoryDialog(index);
                              },
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _loginButtonClickCount = 0; // 重置计数器
              });
            },
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('login_history');
              setState(() {
                _loginHistory = [];
                _loginButtonClickCount = 0; // 重置计数器
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('历史记录已清空')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空历史'),
          ),
        ],
      ),
    );
  }
  
  // 添加编辑历史记录的对话框
  void _showEditHistoryDialog(int index) {
    final record = _loginHistory[index];
    final usernameController = TextEditingController(text: record['username']);
    final serverController = TextEditingController(text: record['server']);
    final passwordController = TextEditingController(
      text: record.containsKey('password') ? record['password'] : ''
    );
    bool savePassword = record.containsKey('password');
    bool obscureEditPassword = true; // 添加密码显示/隐藏状态
    
    Navigator.pop(context); // 先关闭历史记录对话框
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, color: Colors.pink),
              const SizedBox(width: 8),
              const Text('编辑登录信息'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serverController,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    prefixIcon: Icon(Icons.dns),
                    hintText: '请输入完整的服务器地址',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureEditPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureEditPassword = !obscureEditPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureEditPassword,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: savePassword,
                      onChanged: (value) {
                        setState(() {
                          savePassword = value ?? false;
                        });
                      },
                      activeColor: Colors.pink,
                    ),
                    const Text('记住密码'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showLoginHistoryDialog(); // 重新打开历史记录对话框
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                // 更新记录
                setState(() {
                  _loginHistory[index]['username'] = usernameController.text;
                  _loginHistory[index]['server'] = serverController.text;
                  
                  if (savePassword && passwordController.text.isNotEmpty) {
                    _loginHistory[index]['password'] = passwordController.text;
                  } else if (!savePassword) {
                    _loginHistory[index].remove('password');
                  }
                });
                
                // 保存到SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                prefs.setString('login_history', json.encode(_loginHistory));
                
                Navigator.pop(context);
                _showLoginHistoryDialog(); // 重新打开历史记录对话框
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('登录信息已更新')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.pink),
              child: const Text('保存'),
            ),
            TextButton(
              onPressed: () async {
                // 删除记录
                setState(() {
                  _loginHistory.removeAt(index);
                });
                
                // 保存到SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                prefs.setString('login_history', json.encode(_loginHistory));
                
                Navigator.pop(context);
                _showLoginHistoryDialog(); // 重新打开历史记录对话框
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('登录记录已删除')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        ),
      ),
    );
  }

  // 检查数据库连接状态
  Future<void> _checkDbStatus() async {
    if (_serverController.text.isEmpty) {
      setState(() {
        _isDbConnected = false;
        _dbStatusMessage = '请输入服务器地址';
      });
      return;
    }
    
    setState(() {
      _isCheckingDbStatus = true;
      _dbStatusMessage = '正在检测连接...';
    });
    
    try {
      // 更新API服务的基础URL
      _apiService.setBaseUrl(_serverController.text);
      
      final result = await _apiService.checkDbStatus();
      
      setState(() {
        _isCheckingDbStatus = false;
        _isDbConnected = result['connected'];
        _dbStatusMessage = result['message'];
      });
    } catch (e) {
      setState(() {
        _isCheckingDbStatus = false;
        _isDbConnected = false;
        _dbStatusMessage = '连接失败: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 强制恢复输入值，确保不会在重建过程中丢失
    _restoreInputValues();
    
    return WillPopScope(
      // 处理返回按钮，避免返回导致的状态丢失
      onWillPop: () async {
        // 保存当前输入值
        _currentUsername = _usernameController.text;
        _currentPassword = _passwordController.text;
        _currentServer = _serverController.text;
        return true;
      },
      child: GestureDetector(
        // 点击空白处关闭键盘，避免键盘反复弹出导致的问题
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 70,
                          color: Colors.pink,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '爱 迹',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _serverController,
                          decoration: InputDecoration(
                            labelText: '服务器地址',
                            prefixIcon: GestureDetector(
                              onTap: _isCheckingDbStatus ? null : _checkDbStatus,
                              child: Tooltip(
                                message: '点击检测连接状态',
                                child: Icon(
                                  Icons.dns,
                                  color: _isCheckingDbStatus
                                      ? Colors.orange
                                      : _isDbConnected
                                          ? Colors.green
                                          : Colors.red[700],
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入服务器地址';
                            }
                            return null;
                          },
                          focusNode: _serverFocus,
                          onFieldSubmitted: (value) {
                            FocusScope.of(context).unfocus();
                            _checkDbStatus();  // 当服务器地址输入完成时检查连接
                          },
                          onSaved: (value) {
                            _currentServer = value!;
                          },
                        ),
                        // 显示数据库连接状态消息
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _isCheckingDbStatus 
                                  ? '正在检测连接...' 
                                  : '服务器状态: $_dbStatusMessage',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: _isCheckingDbStatus ? FontStyle.italic : FontStyle.normal,
                                color: _isCheckingDbStatus
                                    ? Colors.orange
                                    : _isDbConnected
                                        ? Colors.green
                                        : Colors.red[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                          focusNode: _usernameFocus,
                          onFieldSubmitted: (value) {
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          },
                          onSaved: (value) {
                            _currentUsername = value!;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                          focusNode: _passwordFocus,
                          onSaved: (value) {
                            _currentPassword = value!;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberPassword,
                              onChanged: (value) {
                                setState(() {
                                  _rememberPassword = value ?? false;
                                });
                              },
                              activeColor: Colors.pink,
                            ),
                            const Text(
                              '记住密码',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.pink,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterScreen(
                                      initialServerUrl: _serverController.text,
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                              child: const Text(
                                '注册',
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPasswordScreen(
                                      initialServerUrl: _serverController.text,
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                              child: const Text(
                                '忘记密码',
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : const Text(
                                          '登录',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 45,
                              width: 45,
                              child: ElevatedButton(
                                onPressed: _showLoginHistoryDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[50],
                                  foregroundColor: Colors.pink,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(
                                  Icons.history,
                                  size: 22,
                                  color: Colors.pink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}