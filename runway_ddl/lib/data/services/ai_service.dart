import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/models/parse_result.dart';

abstract class AIService {
  Future<ParseResult> parseText(String input);
  Future<ParseResult> parseImage(String imagePath);
}

class AIServiceImpl implements AIService {
  final Dio _dio;
  final String baseUrl;
  final String apiKey;
  final String textModel;
  final String imageModel;

  static const Duration _timeout = Duration(seconds: 30);

  AIServiceImpl({
    required this.baseUrl,
    required this.apiKey,
    this.textModel = 'qwen-plus',
    this.imageModel = 'qwen-vl-plus',
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: _timeout,
           receiveTimeout: _timeout,
           headers: {
             'Authorization': 'Bearer $apiKey',
             'Content-Type': 'application/json',
           },
         ),
       );

  @override
  Future<ParseResult> parseText(String input) async {
    try {
      final prompt =
          '''请从以下自然语言描述中提取任务信息，返回 JSON 格式：

输入：$input

返回格式：
{
  "title": "任务标题",
  "date": "YYYY-MM-DD 或相对日期描述",
  "time": "HH:MM 或 null",
  "category_hint": "分类关键词",
  "priority": "high/medium/low"
}''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': textModel,
          'messages': [
            {
              'role': 'system',
              'content': '你是一个任务信息提取助手。请严格按照 JSON 格式返回结果，不要添加任何其他文字。',
            },
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      final content =
          response.data['choices'][0]['message']['content'] as String;
      return _parseTextResponse(content);
    } on DioException catch (e) {
      return ParseResult.failed(_handleDioError(e));
    } catch (e) {
      return ParseResult.failed('解析失败: $e');
    }
  }

  @override
  Future<ParseResult> parseImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return ParseResult.failed('图片文件不存在');
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = '''请分析这张图片，提取其中的任务信息：

1. 如果是课程表：提取课程名称、时间、地点
2. 如果是会议白板：提取会议主题、时间、待办事项
3. 如果是手写便签：提取文字内容中的任务信息
4. 如果是截图：提取其中的截止日期、任务描述

返回 JSON 格式：
{
  "title": "任务标题",
  "date": "YYYY-MM-DD",
  "time": "HH:MM 或 null",
  "category_hint": "分类关键词",
  "priority": "high/medium/low",
  "ocr_text": "图片中识别的原始文字"
}''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': imageModel,
          'messages': [
            {
              'role': 'system',
              'content': '你是一个图像分析助手，专门提取任务相关信息。请严格按照 JSON 格式返回结果，不要添加任何其他文字。',
            },
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
              ],
            },
          ],
        },
      );

      final content =
          response.data['choices'][0]['message']['content'] as String;
      return _parseImageResponse(content);
    } on DioException catch (e) {
      return ParseResult.failed(_handleDioError(e));
    } catch (e) {
      return ParseResult.failed('图片解析失败: $e');
    }
  }

  ParseResult _parseTextResponse(String content) {
    try {
      final jsonStr = _extractJson(content);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return ParseResult(
        title: json['title'] as String?,
        date: _parseDate(json['date'] as String?),
        time: json['time'] as String?,
        categoryHint: json['category_hint'] as String?,
        priority: _parsePriority(json['priority'] as String?),
        confidence: 0.8,
        success: true,
      );
    } catch (e) {
      return ParseResult.failed('JSON 解析失败: $e');
    }
  }

  ParseResult _parseImageResponse(String content) {
    try {
      final jsonStr = _extractJson(content);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return ParseResult(
        title: json['title'] as String?,
        date: _parseDate(json['date'] as String?),
        time: json['time'] as String?,
        categoryHint: json['category_hint'] as String?,
        priority: _parsePriority(json['priority'] as String?),
        confidence: 0.8,
        success: true,
        ocrText: json['ocr_text'] as String?,
      );
    } catch (e) {
      return ParseResult.failed('JSON 解析失败: $e');
    }
  }

  String _extractJson(String content) {
    final startIndex = content.indexOf('{');
    final endIndex = content.lastIndexOf('}');
    if (startIndex == -1 || endIndex == -1) {
      throw FormatException('未找到有效的 JSON 格式');
    }
    return content.substring(startIndex, endIndex + 1);
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    final normalizedStr = dateStr.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (normalizedStr) {
      case '今天':
      case '今日':
        return today;
      case '明天':
      case '明日':
        return today.add(const Duration(days: 1));
      case '后天':
        return today.add(const Duration(days: 2));
      case '下周':
      case '下星期':
        return today.add(const Duration(days: 7));
      default:
        try {
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        } catch (_) {}
    }
    return null;
  }

  ItemPriority _parsePriority(String? priorityStr) {
    if (priorityStr == null) return ItemPriority.medium;
    switch (priorityStr.toLowerCase()) {
      case 'high':
      case '高':
        return ItemPriority.high;
      case 'low':
      case '低':
        return ItemPriority.low;
      default:
        return ItemPriority.medium;
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '请求超时，请检查网络连接';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'API Key 无效';
        } else if (statusCode == 429) {
          return '请求过于频繁，请稍后再试';
        }
        return '服务器错误: $statusCode';
      case DioExceptionType.connectionError:
        return '网络连接失败';
      default:
        return '请求失败: ${e.message}';
    }
  }
}
