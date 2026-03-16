import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:runway_ddl/data/models/ai_config.dart';
import 'package:runway_ddl/data/models/appearance_config.dart';
import 'package:runway_ddl/presentation/providers/ai_provider.dart';
import 'package:runway_ddl/presentation/providers/appearance_provider.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiConfig = ref.watch(aIConfigNotifierProvider);
    final appearanceConfig = ref.watch(appearanceConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(context, '外观'),
          _buildAppearanceTile(context, appearanceConfig),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'AI 配置'),
          _buildAiConfigTile(context, aiConfig),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '数据管理'),
          _buildClearDataTile(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '关于'),
          _buildVersionTile(),
          _buildPrivacyPolicyTile(context),
          _buildFeedbackTile(context),
        ],
      ),
    );
  }

  Widget _buildAppearanceTile(
    BuildContext context,
    AppearanceConfig appearanceConfig,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = appearanceConfig.useDynamicColor && Platform.isAndroid
        ? '已启用 Android 动态取色'
        : '当前主题色 ${appearanceConfig.seedColorHex}';

    return _SettingsTile(
      title: '外观与主题',
      subtitle: subtitle,
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: () => context.push('/settings/appearance'),
    );
  }

  Widget _buildAiConfigTile(BuildContext context, AIConfig aiConfig) {
    final colorScheme = Theme.of(context).colorScheme;
    final configured = aiConfig.hasApiKey;

    return _SettingsTile(
      title: 'AI 接口配置',
      subtitle: configured ? '已配置 ${aiConfig.model}' : '未配置 API Key，AI 功能暂不可用',
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: () => context.push('/settings/ai-config'),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildClearDataTile(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsTile(
      title: '清除所有数据',
      subtitle: '删除分类、事项、图片和 AI 配置，清除后需重启应用',
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: () => _showFirstConfirmation(context, ref),
    );
  }

  void _showFirstConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('确定要清除所有数据吗？此操作不可恢复，且清除后需重启应用才能完全生效。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSecondConfirmation(context, ref);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSecondConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('再次确认'),
        content: const Text('所有分类、事项、图片和 AI 配置将被永久删除。清除完成后应用会关闭，请重新打开。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData(context, ref);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('我知道风险，继续'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('正在清除数据...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final hiveService = ref.read(hiveServiceProvider);
      await hiveService.clearAll();

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }

      if (context.mounted) {
        Navigator.pop(context);
        if (Platform.isIOS) {
          context.go('/');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('数据已清除。iOS 平台请手动关闭并重新打开应用。')),
          );
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 150));
        _exitApplication();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('清除数据失败: $e')));
      }
    }
  }

  void _exitApplication() {
    exit(0);
  }

  Widget _buildVersionTile() {
    return _SettingsTile(title: '版本信息', subtitle: '0.1.0-alpha.1');
  }

  Widget _buildPrivacyPolicyTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsTile(
      title: '隐私政策',
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('功能开发中'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Widget _buildFeedbackTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsTile(
      title: '用户反馈',
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('功能开发中'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
