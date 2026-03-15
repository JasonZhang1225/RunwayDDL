// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiServiceHash() => r'9e63cbf4327958f8a62e644f46077f552f41b0ef';

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
String _$apiConfigNotifierHash() => r'662e9dbcb1d468f7cc899451b9b77fda02fee70f';

/// See also [ApiConfigNotifier].
@ProviderFor(ApiConfigNotifier)
final apiConfigNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ApiConfigNotifier, ApiConfig?>.internal(
  ApiConfigNotifier.new,
  name: r'apiConfigNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$apiConfigNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ApiConfigNotifier = AutoDisposeAsyncNotifier<ApiConfig?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
