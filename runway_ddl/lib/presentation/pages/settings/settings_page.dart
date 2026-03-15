import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/presentation/providers/api_config_provider.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final apiConfig = ref.watch(apiConfigNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('AI 配置'),
          _buildApiConfigTile(context, apiConfig),
          const SizedBox(height: 16),
          _buildSectionHeader('数据管理'),
          _buildClearDataTile(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader('关于'),
          _buildVersionTile(),
          _buildPrivacyPolicyTile(context),
          _buildFeedbackTile(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildApiConfigTile(
    BuildContext context,
    AsyncValue<ApiConfig?> apiConfig,
  ) {
    final hasApiKey = apiConfig.value?.apiKey.isNotEmpty ?? false;

    return _SettingsTile(
      title: 'API Key 配置',
      subtitle: hasApiKey ? '已配置' : '未配置（无法使用 AI 功能）',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasApiKey)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '已配置',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
      onTap: () => context.push('/settings/api-config'),
    );
  }

  Widget _buildClearDataTile(BuildContext context, WidgetRef ref) {
    return _SettingsTile(
      title: '清除所有数据',
      subtitle: '删除所有数据并退出应用，需手动重启',
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: () => _showFirstConfirmation(context, ref),
    );
  }

  void _showFirstConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('确定要清除所有数据吗？此操作不可恢复，应用将会自动退出，需要您手动重新启动。'),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.overdue),
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
        content: const Text('所有数据（包括分类、事项、图片和 API 配置）将被永久删除，应用将自动退出！'),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.overdue),
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
        exit(0);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('清除数据失败：$e')));
      }
    }
  }

  Widget _buildVersionTile() {
    return _SettingsTile(title: '版本信息', subtitle: '0.1.0-alpha.1');
  }

  Widget _buildPrivacyPolicyTile(BuildContext context) {
    return _SettingsTile(
      title: '隐私政策',
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
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
    return _SettingsTile(
      title: '用户反馈',
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
