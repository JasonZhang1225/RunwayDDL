import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:runway_ddl/data/models/parse_result.dart';
import 'package:runway_ddl/data/services/ai_service.dart';

part 'ai_provider.g.dart';

@riverpod
AIService aiService(AiServiceRef ref) {
  const baseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
  );
  const apiKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');

  return AIServiceImpl(baseUrl: baseUrl, apiKey: apiKey);
}

@riverpod
class TextParser extends _$TextParser {
  @override
  Future<ParseResult> build() async {
    return const ParseResult();
  }

  Future<ParseResult> parse(String input) async {
    if (input.trim().isEmpty) {
      return ParseResult.failed('输入不能为空');
    }

    state = const AsyncValue.loading();
    final service = ref.read(aiServiceProvider);
    final result = await service.parseText(input);
    state = AsyncValue.data(result);
    return result;
  }
}

@riverpod
class ImageParser extends _$ImageParser {
  @override
  Future<ParseResult> build() async {
    return const ParseResult();
  }

  Future<ParseResult> parse(String imagePath) async {
    if (imagePath.isEmpty) {
      return ParseResult.failed('图片路径不能为空');
    }

    state = const AsyncValue.loading();
    final service = ref.read(aiServiceProvider);
    final result = await service.parseImage(imagePath);
    state = AsyncValue.data(result);
    return result;
  }
}
