import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/anniversary.dart';
import '../models/memory.dart';
import '../models/whisper.dart';

class ApiService {
  String baseUrl = 'http://localhost:8000/api';
  Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };
  String? _token;
  String? _apiKey;
  
  // 单例模式
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // 设置基础URL
  void setBaseUrl(String url) {
    // 确保URL格式正确
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://' + url;
    }
    // 确保URL以/api结尾
    if (!url.endsWith('/api')) {
      if (url.endsWith('/')) {
        url = url + 'api';
      } else {
        url = url + '/api';
      }
    }
    
    print('API: 设置基础URL为 $url');
    baseUrl = url;
  }
  
  // 设置认证令牌
  void setToken(String token) {
    _token = token;
    _updateHeaders();
  }
  
  // 设置API Key
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    _updateHeaders();
  }
  
  // 更新请求头
  void _updateHeaders() {
    _headers = {
      'Content-Type': 'application/json',
    };
    
    if (_token != null && _token!.isNotEmpty) {
      _headers['Authorization'] = 'Bearer $_token';
    }
    
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _headers['X-API-Key'] = _apiKey!;
    }
  }
  
  // 检查 token 是否存在
  bool get hasToken => _token != null && _token!.isNotEmpty;
  
  // 检查 apiKey 是否存在
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  
  // 用户注册
  Future<Map<String, dynamic>> register(String username, String password, {String? email, String? avatar}) async {
    print('API: 开始注册用户');
    print('API: 请求地址 - $baseUrl/register');
    
    final requestBody = {
      'username': username,
      'password': password,
    };
    
    if (email != null) {
      requestBody['email'] = email;
    }
    
    if (avatar != null) {
      requestBody['avatar'] = avatar;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: jsonEncode(requestBody),
      headers: _headers,
    );
    
    print('API: 响应状态码 - ${response.statusCode}');
    
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print('API: 注册成功 - ${responseData['data']['user']['username']}');
      return responseData['data'];
    } else {
      final error = jsonDecode(response.body)['message'];
      print('API: 注册失败 - $error');
      throw Exception(error);
    }
  }
  
  // 用户登录
  Future<Map<String, dynamic>> login(String username, String password) async {
    print('API: 开始用户登录');
    print('API: 请求地址 - $baseUrl/login');
    
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
      headers: _headers,
    );
    
    print('API: 响应状态码 - ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final data = responseData['data'];
      
      // 设置认证信息
      if (data['token'] != null) {
        setToken(data['token']);
      }
      
      if (data['apikey'] != null) {
        setApiKey(data['apikey']);
      }
      
      print('API: 登录成功 - ${data['user']['username']}');
      return data;
    } else {
      final error = jsonDecode(response.body)['message'];
      print('API: 登录失败 - $error');
      throw Exception(error);
    }
  }
  
  // 修改密码
  Future<void> changePassword(String username, String oldPassword, String newPassword) async {
    print('API: 开始修改密码');
    print('API: 请求地址 - $baseUrl/love/change-password');
    
    final response = await http.post(
      Uri.parse('$baseUrl/love/change-password'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    
    print('API: 响应状态码 - ${response.statusCode}');
    
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['message'];
      print('API: 修改密码失败 - $error');
      throw Exception(error);
    }
    
    print('API: 修改密码成功');
  }
  
  // 更新头像
  Future<String> updateAvatar(String avatar) async {
    print('API: 开始更新头像');
    print('API: 请求地址 - $baseUrl/love/update-avatar');
    
    final response = await http.post(
      Uri.parse('$baseUrl/love/update-avatar'),
      headers: _headers,
      body: jsonEncode({
        'avatar': avatar,
      }),
    );
    
    print('API: 响应状态码 - ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      print('API: 更新头像成功');
      return data['avatar'];
    } else {
      final error = jsonDecode(response.body)['message'];
      print('API: 更新头像失败 - $error');
      throw Exception(error);
    }
  }
  
  // 重置密码 (忘记密码)
  // 注意：这是一个模拟的方法，实际应用中需要根据后端API调整
  Future<void> resetPassword(String username, String newPassword) async {
    print('API: 开始重置密码');
    print('API: 请求地址 - 模拟重置密码接口');
    
    // 这里应调用实际的重置密码接口，目前模拟成功返回
    await Future.delayed(const Duration(seconds: 1));
    
    // 如果有正式的重置密码API，应该替换为实际的API调用
    /*
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'new_password': newPassword,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }
    */
    
    print('API: 重置密码模拟成功');
  }
  
  // 获取情侣状态
  Future<Map<String, dynamic>> getCoupleStatus() async {
    print('API: 开始获取情侣状态');
    print('API: 请求地址 - $baseUrl/love/couple/status');
    
    final response = await http.get(
      Uri.parse('$baseUrl/love/couple/status'),
      headers: _headers,
    );
    
    print('API: 响应状态码 - ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data']['couple_status'];
      print('API: 获取情侣状态成功');
      return data;
    } else {
      final error = jsonDecode(response.body)['message'];
      print('API: 获取情侣状态失败 - $error');
      throw Exception(error);
    }
  }
  
  // 绑定情侣关系
  Future<Map<String, dynamic>> bindCouple(String partnerUsername) async {
    print('API: 开始绑定情侣关系');
    print('API: 请求地址 - $baseUrl/love/couple/bind');
    
    final response = await http.post(
      Uri.parse('$baseUrl/love/couple/bind'),
      headers: _headers,
      body: jsonEncode({
        'partner_username': partnerUsername,
      }),
    );
    
    print('API: 响应状态码 - ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data']['couple_status'];
      print('API: 绑定情侣关系成功');
      return data;
    } else {
      final error = jsonDecode(response.body)['message'];
      print('API: 绑定情侣关系失败 - $error');
      throw Exception(error);
    }
  }
  
  // 解除情侣关系
  Future<void> unbindCouple() async {
    print('API: 开始解除情侣关系');
    print('API: 请求地址 - $baseUrl/love/couple/unbind');
    
    final response = await http.post(
      Uri.parse('$baseUrl/love/couple/unbind'),
      headers: _headers,
    );
    
    print('API: 响应状态码 - ${response.statusCode}');
    
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['message'];
      print('API: 解除情侣关系失败 - $error');
      throw Exception(error);
    }
    
    print('API: 解除情侣关系成功');
  }
  
  // 获取纪念日列表
  Future<List<Anniversary>> getAnniversaries() async {
    print('API: 开始获取纪念日列表');
    print('API: 请求地址 - $baseUrl/love/anniversaries');
    print('API: Headers - $_headers');

    final response = await http.get(
      Uri.parse('$baseUrl/love/anniversaries'),
      headers: _headers,
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('API: 解析后的响应数据 - $responseData');
      
      // 检查响应结构
      if (responseData['code'] == 200 && responseData['data'] != null && responseData['data']['anniversaries'] != null) {
        final anniversaries = responseData['data']['anniversaries'];
        print('API: 纪念日数据 - $anniversaries');
        return (anniversaries as List).map((json) => Anniversary.fromJson(json)).toList();
      } else {
        print('API: 警告 - 纪念日响应结构不符合预期');
        return [];
      }
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 创建纪念日
  Future<Anniversary> createAnniversary({
    required String name,
    required String content,
    String? moodTag,
  }) async {
    print('API: 开始创建纪念日');
    print('API: 请求地址 - $baseUrl/love/anniversaries');
    print('API: Headers - $_headers');
    print('API: 请求数据 - name: $name, content: $content, moodTag: $moodTag');

    final requestBody = {
      'name': name,
      'content': content,
    };

    if (moodTag != null) {
      requestBody['mood_tag'] = moodTag;
    }

    print('API: 请求体 - $requestBody');

    final response = await http.post(
      Uri.parse('$baseUrl/love/anniversaries'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final data = responseData['data']['anniversary'];
      print('API: 创建的纪念日数据 - $data');
      return Anniversary.fromJson(data);
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 更新纪念日
  Future<Anniversary> updateAnniversary({
    required int id,
    required String name,
    required String content,
    String? moodTag,
  }) async {
    print('API: 开始更新纪念日');
    print('API: 请求地址 - $baseUrl/love/anniversaries/$id');
    print('API: Headers - $_headers');
    print('API: 请求数据 - id: $id, name: $name, content: $content, moodTag: $moodTag');

    final requestBody = {
      'name': name,
      'content': content,
    };

    if (moodTag != null) {
      requestBody['mood_tag'] = moodTag;
    }

    print('API: 请求体 - $requestBody');

    final response = await http.put(
      Uri.parse('$baseUrl/love/anniversaries/$id'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final data = responseData['data'];
      print('API: 更新的纪念日数据 - $data');
      return Anniversary.fromJson(data);
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 删除纪念日
  Future<void> deleteAnniversary(int id) async {
    print('API: 开始删除纪念日');
    print('API: 请求地址 - $baseUrl/love/anniversaries/$id');
    print('API: Headers - $_headers');

    final response = await http.delete(
      Uri.parse('$baseUrl/love/anniversaries/$id'),
      headers: _headers,
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      print('API: 删除纪念日成功');
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 获取美好回忆列表
  Future<List<Memory>> getMemories() async {
    print('API: 开始获取美好回忆列表');
    print('API: 请求地址 - $baseUrl/love/memories');
    print('API: Headers - $_headers');

    final response = await http.get(
      Uri.parse('$baseUrl/love/memories'),
      headers: _headers,
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('API: 解析后的响应数据 - $responseData');
      
      // 检查响应结构
      if (responseData['code'] == 200 && responseData['data'] != null && responseData['data']['memories'] != null) {
        final memories = responseData['data']['memories'];
        print('API: 美好回忆数据 - $memories');
        return (memories as List).map((json) => Memory.fromJson(json)).toList();
      } else {
        print('API: 警告 - 美好回忆响应结构不符合预期');
        return [];
      }
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 创建美好回忆
  Future<Memory> createMemory({
    required String title,
    required String content,
    required String image,
    required String moodTag,
    String? avatar,
  }) async {
    print('API: 开始创建美好回忆');
    print('API: 请求地址 - $baseUrl/love/memories');
    print('API: Headers - $_headers');
    print('API: 请求数据 - title: $title, content: $content, moodTag: $moodTag');
    print('API: 图片数据长度 - ${image.length}');
    print('API: 图片数据前100个字符 - ${image.substring(0, image.length > 100 ? 100 : image.length)}');

    final requestBody = {
      'title': title,
      'content': content,
      'image': image,
      'mood_tag': moodTag,
    };

    if (avatar != null) {
      requestBody['avatar'] = avatar;
    }

    print('API: 请求体 - title: ${requestBody['title']}, content: ${requestBody['content']}, moodTag: ${requestBody['mood_tag']}, imageLength: ${image.length}');

    final response = await http.post(
      Uri.parse('$baseUrl/love/memories'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final data = responseData['data']['memory'];
      print('API: 创建的美好回忆数据 - $data');
      return Memory.fromJson(data);
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 更新美好回忆
  Future<Memory> updateMemory({
    required int id,
    required String title,
    required String content,
    required String? image,
    required String moodTag,
    String? avatar,
  }) async {
    print('API: 开始更新美好回忆');
    print('API: 请求地址 - $baseUrl/love/memories/$id');
    print('API: Headers - $_headers');
    print('API: 请求数据 - id: $id, title: $title, content: $content, moodTag: $moodTag');
    if (image != null) {
      print('API: 图片数据长度 - ${image.length}');
      print('API: 图片数据前100个字符 - ${image.substring(0, image.length > 100 ? 100 : image.length)}');
    }

    final requestBody = {
      'title': title,
      'content': content,
      'mood_tag': moodTag,
    };

    if (image != null) {
      requestBody['image'] = image;
    }

    if (avatar != null) {
      requestBody['avatar'] = avatar;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/love/memories/$id'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final data = responseData['data']['memory'];
      print('API: 更新的美好回忆数据 - $data');
      return Memory.fromJson(data);
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 删除美好回忆
  Future<void> deleteMemory(int id) async {
    print('API: 开始删除美好回忆');
    print('API: 请求地址 - $baseUrl/love/memories/$id');
    print('API: Headers - $_headers');

    final response = await http.delete(
      Uri.parse('$baseUrl/love/memories/$id'),
      headers: _headers,
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      print('API: 删除美好回忆成功');
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 获取悄悄话列表
  Future<List<Whisper>> getWhispers() async {
    print('API: 开始获取悄悄话列表');
    print('API: 请求地址 - $baseUrl/love/whispers');
    print('API: Headers - $_headers');

    final response = await http.get(
      Uri.parse('$baseUrl/love/whispers'),
      headers: _headers,
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('API: 解析后的响应数据 - $responseData');
      
      // 检查响应结构
      if (responseData['code'] == 200 && responseData['data'] != null && responseData['data']['whispers'] != null) {
        final whispers = responseData['data']['whispers'];
        print('API: 悄悄话数据 - $whispers');
        return (whispers as List).map((json) => Whisper.fromJson(json)).toList();
      } else {
        print('API: 警告 - 悄悄话响应结构不符合预期');
        return [];
      }
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 创建悄悄话
  Future<Whisper> createWhisper({
    required String content,
    String? avatar,
    String? name,
  }) async {
    print('API: 开始创建悄悄话');
    print('API: 请求地址 - $baseUrl/love/whispers');
    print('API: Headers - $_headers');
    print('API: 请求数据 - content: $content, avatar: $avatar, name: $name');

    final requestBody = {
      'content': content,
    };

    if (avatar != null) {
      requestBody['avatar'] = avatar;
    }

    if (name != null) {
      requestBody['name'] = name;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/love/whispers'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final data = responseData['data']['whisper'];
      print('API: 创建的悄悄话数据 - $data');
      return Whisper.fromJson(data);
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 更新悄悄话
  Future<Whisper> updateWhisper({
    required int id,
    required String content,
    String? avatar,
    String? name,
  }) async {
    print('API: 开始更新悄悄话');
    print('API: 请求地址 - $baseUrl/love/whispers/$id');
    print('API: Headers - $_headers');
    print('API: 请求数据 - id: $id, content: $content, avatar: $avatar, name: $name');

    final requestBody = {
      'content': content,
    };

    if (avatar != null) {
      requestBody['avatar'] = avatar;
    }

    if (name != null) {
      requestBody['name'] = name;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/love/whispers/$id'),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final data = responseData['data']['whisper'];
      print('API: 更新的悄悄话数据 - $data');
      return Whisper.fromJson(data);
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 删除悄悄话
  Future<void> deleteWhisper(int id) async {
    print('API: 开始删除悄悄话');
    print('API: 请求地址 - $baseUrl/love/whispers/$id');
    print('API: Headers - $_headers');

    final response = await http.delete(
      Uri.parse('$baseUrl/love/whispers/$id'),
      headers: _headers,
    );

    print('API: 响应状态码 - ${response.statusCode}');
    print('API: 响应数据 - ${response.body}');

    if (response.statusCode == 200) {
      print('API: 删除悄悄话成功');
    } else {
      print('API: 错误 - ${jsonDecode(response.body)['message']}');
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  // 获取服务器和数据库连接状态
  Future<Map<String, dynamic>> checkDbStatus() async {
    print('API: 开始检查数据库连接状态');
    
    // 从baseUrl中提取基础部分，去掉可能的/api后缀
    String baseUrlWithoutApi = baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrlWithoutApi = baseUrl.substring(0, baseUrl.length - 4);
    }
    
    final testDbUrl = '$baseUrlWithoutApi/test-db';
    print('API: 请求地址 - $testDbUrl');
    
    try {
      final response = await http.get(
        Uri.parse(testDbUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      print('API: 响应状态码 - ${response.statusCode}');
      print('API: 响应数据 - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'connected': true,
          'message': '数据库连接正常',
          'data': data,
        };
      } else {
        return {
          'connected': false,
          'message': '数据库连接异常: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      print('API: 连接错误 - $e');
      return {
        'connected': false,
        'message': '连接失败: ${e.toString()}',
        'data': null,
      };
    }
  }
}