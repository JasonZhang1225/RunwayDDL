import 'package:flutter/foundation.dart';

class AppearanceConfig {
  static const String defaultSeedColorHex = '#2196F3';

  final bool useDynamicColor;
  final String seedColorHex;

  const AppearanceConfig({
    required this.useDynamicColor,
    required this.seedColorHex,
  });

  factory AppearanceConfig.defaults() {
    return AppearanceConfig(
      useDynamicColor: defaultTargetPlatform == TargetPlatform.android,
      seedColorHex: defaultSeedColorHex,
    );
  }

  AppearanceConfig copyWith({bool? useDynamicColor, String? seedColorHex}) {
    return AppearanceConfig(
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      seedColorHex: seedColorHex ?? this.seedColorHex,
    );
  }
}
