import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/models/parse_result.dart';

abstract class AIService {
  Future<ParseResult> parseText(String input, {List<String> categoryNames = const []});
  Future<ParseResult> parseImage(
    String imagePath, {
    List<String> categoryNames = const [],
  });
}

class AIServiceImpl implements AIService {
  final Dio _dio;
  final String baseUrl;
  final String apiKey;
  final String model;

  static const Duration _timeout = Duration(seconds: 30);

  AIServiceImpl({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
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
  Future<ParseResult> parseText(
    String input, {
    List<String> categoryNames = const [],
  }) async {
    final configError = _validateConfig();
    if (configError != null) {
      return ParseResult.failed(configError);
    }

    try {
      final prompt =
          '''${_buildContextPrompt(categoryNames)}

请从以下自然语言描述中提取任务信息，返回 JSON 格式：

输入：$input

返回格式：
{
  "title": "任务标题",
  "date": "YYYY-MM-DD 或 null",
  "time": "HH:MM 或 null",
  "category_hint": "优先使用已有分类名称；不确定时返回简短分类提示或 null",
  "priority": "high/medium/low"
}''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '你是一个任务信息提取助手。请严格按照 JSON 格式返回结果，不要添加任何其他文字。',
            },
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      final content = _extractMessageContent(
        response.data['choices'][0]['message']['content'],
      );
      return _parseTextResponse(content);
    } on DioException catch (e) {
      return ParseResult.failed(_handleDioError(e));
    } catch (e) {
      return ParseResult.failed('解析失败: $e');
    }
  }

  @override
  Future<ParseResult> parseImage(
    String imagePath, {
    List<String> categoryNames = const [],
  }) async {
    final configError = _validateConfig();
    if (configError != null) {
      return ParseResult.failed(configError);
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return ParseResult.failed('图片文件不存在');
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = '''${_buildContextPrompt(categoryNames)}

请分析这张图片，提取其中的任务信息：

1. 如果是课程表：提取课程名称、时间、地点
2. 如果是会议白板：提取会议主题、时间、待办事项
3. 如果是手写便签：提取文字内容中的任务信息
4. 如果是截图：提取其中的截止日期、任务描述

返回 JSON 格式：
{
  "title": "任务标题",
  "date": "YYYY-MM-DD 或 null",
  "time": "HH:MM 或 null",
  "category_hint": "优先使用已有分类名称；不确定时返回简短分类提示或 null",
  "priority": "high/medium/low",
  "ocr_text": "图片中识别的原始文字"
}''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
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
                  'image_url': {
                    'url':
                        'data:${_inferMimeType(imagePath)};base64,$base64Image',
                  },
                },
              ],
            },
          ],
        },
      );

      final content = _extractMessageContent(
        response.data['choices'][0]['message']['content'],
      );
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
        title: _parseNullableString(json['title']),
        date: _parseDate(json['date'] as String?),
        time: _parseNullableString(json['time']),
        categoryHint: _parseNullableString(json['category_hint']),
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
        title: _parseNullableString(json['title']),
        date: _parseDate(json['date'] as String?),
        time: _parseNullableString(json['time']),
        categoryHint: _parseNullableString(json['category_hint']),
        priority: _parsePriority(json['priority'] as String?),
        confidence: 0.8,
        success: true,
        ocrText: _parseNullableString(json['ocr_text']),
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

  String? _validateConfig() {
    if (apiKey.trim().isEmpty) {
      return '请先在设置页配置 AI API Key';
    }
    if (baseUrl.trim().isEmpty) {
      return 'AI Base URL 未配置';
    }
    if (model.trim().isEmpty) {
      return 'AI 模型未配置';
    }
    return null;
  }

  String _extractMessageContent(dynamic content) {
    if (content is String) {
      return content;
    }
    if (content is List) {
      final buffer = StringBuffer();
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final text = item['text'];
          if (text is String && text.isNotEmpty) {
            if (buffer.isNotEmpty) {
              buffer.writeln();
            }
            buffer.write(text);
          }
        }
      }
      if (buffer.isNotEmpty) {
        return buffer.toString();
      }
    }
    throw const FormatException('模型返回内容为空');
  }

  String _inferMimeType(String imagePath) {
    final normalized = imagePath.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    if (normalized.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    final normalizedStr = dateStr.trim();
    return app_utils.DateUtils.parseRelativeDate(normalizedStr);
  }

  String? _parseNullableString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return null;
    }
    return normalized;
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
        } else if (statusCode == 400) {
          final message = e.response?.data?['error']?['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
          return '请求参数错误，请检查模型和接口地址';
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

  String _buildContextPrompt(List<String> categoryNames) {
    final now = DateTime.now();
    final currentTime =
        '${app_utils.DateUtils.formatDate(now)} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${app_utils.DateUtils.weekdayLabels[now.weekday - 1]}';
    final calendar = _buildCalendarWindow(now, 21);
    final categories = categoryNames.isEmpty
        ? '- 无现有分类'
        : categoryNames.map((name) => '- $name').join('\n');

    return '''当前时间：$currentTime

未来21天简单日历：
$calendar

当前已有分类：
$categories

规则：
1. 日期优先输出 YYYY-MM-DD，无法确定时返回 null。
2. “周五”“下周”“下周一”“月底”必须基于上面的当前时间和日历判断。
3. 分类优先从“当前已有分类”里选择最接近的一项写入 category_hint。
4. 不要猜去年或其他年份，原文没写年份时按最近的合理未来日期理解。''';
  }

  String _buildCalendarWindow(DateTime start, int days) {
    final today = DateTime(start.year, start.month, start.day);
    final lines = <String>[];

    for (var i = 0; i < days; i++) {
      final date = today.add(Duration(days: i));
      final tags = <String>[];
      if (i == 0) {
        tags.add('今天');
      } else if (i == 1) {
        tags.add('明天');
      }
      if (date.difference(app_utils.DateUtils.nextWeek()).inDays >= 0 &&
          date.difference(app_utils.DateUtils.nextWeek()).inDays < 7) {
        tags.add('下周');
      }

      final tagSuffix = tags.isEmpty ? '' : ' (${tags.join('，')})';
      lines.add(
        '${app_utils.DateUtils.formatDate(date)} '
        '${app_utils.DateUtils.weekdayLabels[date.weekday - 1]}$tagSuffix',
      );
    }

    return lines.join('\n');
  }
}
