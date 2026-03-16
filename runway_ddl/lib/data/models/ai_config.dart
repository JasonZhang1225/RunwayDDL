class AIConfig {
  static const String defaultBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
  );
  static const String defaultModel = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'qwen3.5-flash',
  );
  static const String defaultApiKey = String.fromEnvironment(
    'AI_API_KEY',
    defaultValue: '',
  );

  final String apiKey;
  final String baseUrl;
  final String model;

  const AIConfig({
    this.apiKey = defaultApiKey,
    this.baseUrl = defaultBaseUrl,
    this.model = defaultModel,
  });

  bool get hasApiKey => apiKey.trim().isNotEmpty;
}
