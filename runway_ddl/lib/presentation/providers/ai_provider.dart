import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:runway_ddl/data/models/ai_config.dart';
import 'package:runway_ddl/data/models/parse_result.dart';
import 'package:runway_ddl/data/services/ai_config_service.dart';
import 'package:runway_ddl/data/services/ai_service.dart';
import 'package:runway_ddl/data/services/hive_service.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';

part 'ai_provider.g.dart';

@riverpod
AIConfigService aiConfigService(AiConfigServiceRef ref) {
  return AIConfigService(HiveService());
}

@riverpod
AIService aiService(AiServiceRef ref) {
  final config = ref.watch(aIConfigNotifierProvider);
  return AIServiceImpl(
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
    model: config.model,
  );
}

@riverpod
class AIConfigNotifier extends _$AIConfigNotifier {
  @override
  AIConfig build() {
    return ref.read(aiConfigServiceProvider).loadConfig();
  }

  Future<void> saveConfig(AIConfig config) async {
    final saved = await ref.read(aiConfigServiceProvider).saveConfig(config);
    state = saved;
  }
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
    final categoryNames = (ref.read(categoriesProvider).valueOrNull ?? [])
        .map((category) => category.name)
        .toList();
    final result = await service.parseText(
      input,
      categoryNames: categoryNames,
    );
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
    final categoryNames = (ref.read(categoriesProvider).valueOrNull ?? [])
        .map((category) => category.name)
        .toList();
    final result = await service.parseImage(
      imagePath,
      categoryNames: categoryNames,
    );
    state = AsyncValue.data(result);
    return result;
  }
}
