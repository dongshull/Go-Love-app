import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  /// 将图片文件转换为Base64字符串
  static Future<String?> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('图片转Base64错误: $e');
      return null;
    }
  }
  
  /// 从XFile转换为Base64字符串
  static Future<String?> xFileToBase64(XFile xFile) async {
    try {
      final bytes = await xFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('XFile转Base64错误: $e');
      return null;
    }
  }

  /// 将Base64字符串转换为图像Widget
  static Widget base64ToImage(String? base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    if (base64String == null || base64String.isEmpty) {
      return errorWidget ?? const Icon(Icons.person, color: Colors.white);
    }

    try {
      // 处理可能的URL或Base64前缀
      String sanitizedString = base64String;
      
      // 如果是URL，直接返回网络图片
      if (base64String.startsWith('http')) {
        return Image.network(
          base64String,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('网络图片加载错误: $error');
            return errorWidget ?? const Icon(Icons.error, color: Colors.red);
          },
        );
      }
      
      // 处理base64前缀
      if (base64String.contains(';base64,')) {
        sanitizedString = base64String.split(';base64,')[1];
      } else if (base64String.startsWith('data:image')) {
        sanitizedString = base64String.split(',')[1];
      }

      // 去掉可能的空格和换行符
      sanitizedString = sanitizedString.trim().replaceAll('\n', '');
      
      // 为了安全起见，我们添加padding
      int padLength = 4 - sanitizedString.length % 4;
      if (padLength < 4) {
        sanitizedString = sanitizedString + ('=' * padLength);
      }

      try {
        // 解码Base64
        final Uint8List bytes = base64Decode(sanitizedString);
        
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('Base64图片解析错误: $error');
            return errorWidget ?? const Icon(Icons.error, color: Colors.red);
          },
        );
      } catch (e) {
        print('Base64解码错误: $e');
        return errorWidget ?? const Icon(Icons.error, color: Colors.red);
      }
    } catch (e) {
      print('处理图片出错: $e');
      return errorWidget ?? const Icon(Icons.error, color: Colors.red);
    }
  }

  /// 检查字符串是否为有效的Base64编码图片
  static bool isValidBase64Image(String? string) {
    if (string == null || string.isEmpty) return false;
    
    try {
      // 如果是URL，不当作Base64处理
      if (string.startsWith('http')) {
        return false;
      }
      
      // 处理可能的URL或Base64前缀
      String sanitizedString = string;
      if (string.contains(';base64,')) {
        sanitizedString = string.split(';base64,')[1];
      } else if (string.startsWith('data:image')) {
        sanitizedString = string.split(',')[1];
      }
      
      // 去掉可能的空格和换行符
      sanitizedString = sanitizedString.trim().replaceAll('\n', '');
      
      // 尝试解码
      base64Decode(sanitizedString);
      return true;
    } catch (e) {
      print('Base64验证错误: $e');
      return false;
    }
  }
  
  /// 从相册选择图片并返回Base64字符串
  static Future<String?> pickImageAsBase64({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 800,
    int maxHeight = 800,
    int imageQuality = 70,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (image == null) return null;
      
      // 转换为base64
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // 获取图片扩展名
      String extension = 'jpeg';
      if (image.path.toLowerCase().endsWith('.png')) {
        extension = 'png';
      } else if (image.path.toLowerCase().endsWith('.gif')) {
        extension = 'gif';
      } else if (image.path.toLowerCase().endsWith('.webp')) {
        extension = 'webp';
      }
      
      // 根据接口文档要求格式化Base64字符串
      // 有些API可能需要带前缀，有些可能只需要Base64编码部分
      // 此处提供两种格式，具体使用哪种取决于服务器要求
      
      // 如果API需要完整的data URI格式
      final dataUri = 'data:image/$extension;base64,$base64String';
      
      // 如果图片太大，打印警告
      if (base64String.length > 1000000) { // 约1MB的Base64数据
        print('警告: 图片较大 (${(base64String.length / 1000000).toStringAsFixed(2)}MB)，可能会导致上传失败');
      }
      
      return dataUri; // 或者直接返回 base64String，取决于API要求
    } catch (e) {
      print('选择图片错误: $e');
      return null;
    }
  }
} 