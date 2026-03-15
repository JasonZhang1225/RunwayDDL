import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:runway_ddl/data/models/parse_result.dart';
import 'package:runway_ddl/data/services/ai_service.dart';
import 'package:runway_ddl/data/services/hive_service.dart';

part 'api_config_provider.g.dart';

class ApiConfig {
  final String baseUrl;
  final String apiKey;
  final String textModel;
  final String imageModel;

  ApiConfig({
    required this.baseUrl,
    required this.apiKey,
    this.textModel = 'qwen-plus',
    this.imageModel = 'qwen-vl-plus',
  });
}

@riverpod
class ApiConfigNotifier extends _$ApiConfigNotifier {
  @override
  Future<ApiConfig?> build() async {
    return _loadConfig();
  }

  Future<ApiConfig?> _loadConfig() async {
    try {
      final settingsBox = HiveService().settingsBox;
      final baseUrl =
          settingsBox.get(
                'api_base_url',
                defaultValue:
                    'https://dashscope.aliyuncs.com/compatible-mode/v1',
              )
              as String;
      final apiKey = settingsBox.get('api_key', defaultValue: '') as String;
      final textModel =
          settingsBox.get('text_model', defaultValue: 'qwen-plus') as String;
      final imageModel =
          settingsBox.get('image_model', defaultValue: 'qwen-vl-plus')
              as String;

      return ApiConfig(
        baseUrl: baseUrl,
        apiKey: apiKey,
        textModel: textModel,
        imageModel: imageModel,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveConfig({
    required String baseUrl,
    required String apiKey,
    required String textModel,
    required String imageModel,
  }) async {
    state = const AsyncValue.loading();

    try {
      final settingsBox = HiveService().settingsBox;
      await settingsBox.put('api_base_url', baseUrl);
      await settingsBox.put('api_key', apiKey);
      await settingsBox.put('text_model', textModel);
      await settingsBox.put('image_model', imageModel);

      state = AsyncValue.data(
        ApiConfig(
          baseUrl: baseUrl,
          apiKey: apiKey,
          textModel: textModel,
          imageModel: imageModel,
        ),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> clearConfig() async {
    try {
      final settingsBox = HiveService().settingsBox;
      await settingsBox.delete('api_base_url');
      await settingsBox.delete('api_key');

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<ParseResult> testConnection({
    required String baseUrl,
    required String apiKey,
    String? model,
  }) async {
    try {
      final service = AIServiceImpl(
        baseUrl: baseUrl,
        apiKey: apiKey,
        textModel: model ?? 'qwen-plus',
      );
      final result = await service.parseText('测试');

      if (result.success) {
        return ParseResult(success: true, confidence: 1.0, title: '测试成功');
      } else {
        return ParseResult.failed(result.errorMessage ?? '测试失败');
      }
    } catch (e) {
      return ParseResult.failed('测试失败：$e');
    }
  }
}

@riverpod
AIService aiService(AiServiceRef ref) {
  final config = ref.watch(apiConfigNotifierProvider).value;

  if (config == null || config.apiKey.isEmpty) {
    throw StateError('API Key 未配置，请前往设置页配置');
  }

  return AIServiceImpl(
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
    textModel: config.textModel,
    imageModel: config.imageModel,
  );
}
