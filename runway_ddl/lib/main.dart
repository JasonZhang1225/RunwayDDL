import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:runway_ddl/core/router/app_router.dart';
import 'package:runway_ddl/core/constants/app_theme.dart';
import 'package:runway_ddl/core/utils/color_utils.dart';
import 'package:runway_ddl/data/services/hive_service.dart';
import 'package:runway_ddl/presentation/providers/appearance_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearanceConfig = ref.watch(appearanceConfigProvider);
    final seedColor = ColorUtils.fromHex(appearanceConfig.seedColorHex);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final theme = AppTheme.lightTheme(
          seedColor: seedColor,
          dynamicColorScheme: appearanceConfig.useDynamicColor
              ? lightDynamic
              : null,
        );

        return MaterialApp.router(
          title: 'RunwayDDL',
          theme: theme,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
