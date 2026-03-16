import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runway_ddl/data/models/appearance_config.dart';
import 'package:runway_ddl/data/services/appearance_config_service.dart';
import 'package:runway_ddl/data/services/hive_service.dart';

final appearanceConfigServiceProvider = Provider<AppearanceConfigService>((
  ref,
) {
  return AppearanceConfigService(HiveService());
});

final appearanceConfigProvider =
    NotifierProvider<AppearanceConfigNotifier, AppearanceConfig>(
      AppearanceConfigNotifier.new,
    );

class AppearanceConfigNotifier extends Notifier<AppearanceConfig> {
  @override
  AppearanceConfig build() {
    return ref.read(appearanceConfigServiceProvider).loadConfig();
  }

  Future<void> save(AppearanceConfig config) async {
    state = await ref.read(appearanceConfigServiceProvider).saveConfig(config);
  }
}
