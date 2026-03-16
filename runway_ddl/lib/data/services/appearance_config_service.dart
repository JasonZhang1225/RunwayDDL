import 'package:runway_ddl/data/models/appearance_config.dart';
import 'package:runway_ddl/data/services/hive_service.dart';

class AppearanceConfigService {
  static const String _useDynamicColorKey = 'appearance_use_dynamic_color';
  static const String _seedColorHexKey = 'appearance_seed_color_hex';

  final HiveService _hiveService;

  const AppearanceConfigService(this._hiveService);

  AppearanceConfig loadConfig() {
    final defaults = AppearanceConfig.defaults();
    final settingsBox = _hiveService.settingsBox;

    return AppearanceConfig(
      useDynamicColor:
          settingsBox.get(
                _useDynamicColorKey,
                defaultValue: defaults.useDynamicColor,
              )
              as bool,
      seedColorHex:
          settingsBox.get(_seedColorHexKey, defaultValue: defaults.seedColorHex)
              as String,
    );
  }

  Future<AppearanceConfig> saveConfig(AppearanceConfig config) async {
    final settingsBox = _hiveService.settingsBox;
    await settingsBox.put(_useDynamicColorKey, config.useDynamicColor);
    await settingsBox.put(_seedColorHexKey, config.seedColorHex);
    return config;
  }
}
