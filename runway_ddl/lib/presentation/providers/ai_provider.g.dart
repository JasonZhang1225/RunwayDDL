// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiConfigServiceHash() => r'870b5fcec93dfeb8d503822be0ae72ebce1fbf78';

/// See also [aiConfigService].
@ProviderFor(aiConfigService)
final aiConfigServiceProvider = AutoDisposeProvider<AIConfigService>.internal(
  aiConfigService,
  name: r'aiConfigServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiConfigServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AiConfigServiceRef = AutoDisposeProviderRef<AIConfigService>;
String _$aiServiceHash() => r'f69d9dc09eb1017d3f6388f873845fc619d04b60';

/// See also [aiService].
@ProviderFor(aiService)
final aiServiceProvider = AutoDisposeProvider<AIService>.internal(
  aiService,
  name: r'aiServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$aiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AiServiceRef = AutoDisposeProviderRef<AIService>;
String _$aIConfigNotifierHash() => r'c3392bb5d22d7e155bc0d5971fcd6c9fa492c42d';

/// See also [AIConfigNotifier].
@ProviderFor(AIConfigNotifier)
final aIConfigNotifierProvider =
    AutoDisposeNotifierProvider<AIConfigNotifier, AIConfig>.internal(
  AIConfigNotifier.new,
  name: r'aIConfigNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aIConfigNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AIConfigNotifier = AutoDisposeNotifier<AIConfig>;
String _$textParserHash() => r'00bb0811bd232314366912bb3b7a64bfe464e8e1';

/// See also [TextParser].
@ProviderFor(TextParser)
final textParserProvider =
    AutoDisposeAsyncNotifierProvider<TextParser, ParseResult>.internal(
  TextParser.new,
  name: r'textParserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$textParserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TextParser = AutoDisposeAsyncNotifier<ParseResult>;
String _$imageParserHash() => r'123aac80793b3b82d78e0f74e52ce2865cf443c7';

/// See also [ImageParser].
@ProviderFor(ImageParser)
final imageParserProvider =
    AutoDisposeAsyncNotifierProvider<ImageParser, ParseResult>.internal(
  ImageParser.new,
  name: r'imageParserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$imageParserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ImageParser = AutoDisposeAsyncNotifier<ParseResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
