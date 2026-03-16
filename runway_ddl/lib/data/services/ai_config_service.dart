import 'package:runway_ddl/data/models/ai_config.dart';
import 'package:runway_ddl/data/services/hive_service.dart';

class AIConfigService {
  static const String _apiKeyKey = 'ai_api_key';
  static const String _baseUrlKey = 'ai_base_url';
  static const String _modelKey = 'ai_model';

  final HiveService _hiveService;

  const AIConfigService(this._hiveService);

  AIConfig loadConfig() {
    final settingsBox = _hiveService.settingsBox;

    return AIConfig(
      apiKey:
          (settingsBox.get(_apiKeyKey, defaultValue: AIConfig.defaultApiKey)
                  as String)
              .trim(),
      baseUrl: _normalizeBaseUrl(
        _fallbackIfBlank(
          settingsBox.get(_baseUrlKey, defaultValue: AIConfig.defaultBaseUrl)
              as String,
          AIConfig.defaultBaseUrl,
        ),
      ),
      model: _fallbackIfBlank(
        (settingsBox.get(_modelKey, defaultValue: AIConfig.defaultModel)
                as String)
            .trim(),
        AIConfig.defaultModel,
      ),
    );
  }

  Future<AIConfig> saveConfig(AIConfig config) async {
    final normalized = AIConfig(
      apiKey: config.apiKey.trim(),
      baseUrl: _normalizeBaseUrl(
        _fallbackIfBlank(config.baseUrl, AIConfig.defaultBaseUrl),
      ),
      model: _fallbackIfBlank(config.model.trim(), AIConfig.defaultModel),
    );

    final settingsBox = _hiveService.settingsBox;
    await settingsBox.put(_apiKeyKey, normalized.apiKey);
    await settingsBox.put(_baseUrlKey, normalized.baseUrl);
    await settingsBox.put(_modelKey, normalized.model);

    return normalized;
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String _fallbackIfBlank(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }
}
