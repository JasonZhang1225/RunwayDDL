import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runway_ddl/core/utils/color_utils.dart';
import 'package:runway_ddl/data/models/appearance_config.dart';
import 'package:runway_ddl/presentation/providers/appearance_provider.dart';

class AppearancePage extends ConsumerStatefulWidget {
  const AppearancePage({super.key});

  @override
  ConsumerState<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends ConsumerState<AppearancePage> {
  static const List<String> _seedColors = [
    '#F44336',
    '#E91E63',
    '#9C27B0',
    '#673AB7',
    '#3F51B5',
    '#2196F3',
    '#0091EA',
    '#00ACC1',
    '#00897B',
    '#43A047',
    '#7CB342',
    '#C0CA33',
    '#FFB300',
    '#FB8C00',
    '#F4511E',
    '#6D4C41',
    '#546E7A',
  ];

  bool _initialized = false;
  bool _useDynamicColor = false;
  String _seedColorHex = AppearanceConfig.defaultSeedColorHex;
  bool _isSaving = false;

  bool get _supportsAndroidDynamicColor => Platform.isAndroid;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appearanceConfigProvider);
    if (!_initialized) {
      _useDynamicColor = config.useDynamicColor;
      _seedColorHex = config.seedColorHex;
      _initialized = true;
    }

    final previewScheme = ColorScheme.fromSeed(
      seedColor: ColorUtils.fromHex(_seedColorHex),
      brightness: Brightness.light,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('外观')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPreviewCard(previewScheme),
          const SizedBox(height: 24),
          if (_supportsAndroidDynamicColor) _buildDynamicColorToggle(),
          if (_supportsAndroidDynamicColor) const SizedBox(height: 16),
          _buildIntroText(),
          const SizedBox(height: 16),
          _buildSeedColorGrid(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '主题预览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPreviewSwatch('主色', scheme.primary, scheme.onPrimary),
              _buildPreviewSwatch(
                '强调',
                scheme.primaryContainer,
                scheme.onPrimaryContainer,
              ),
              _buildPreviewSwatch(
                '表面',
                scheme.surfaceContainerHighest,
                scheme.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSwatch(String label, Color color, Color textColor) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDynamicColorToggle() {
    return SwitchListTile.adaptive(
      value: _useDynamicColor,
      contentPadding: EdgeInsets.zero,
      title: const Text('优先使用 Android 莫奈动态色'),
      subtitle: const Text('Android 12+ 可直接跟随系统壁纸配色。'),
      onChanged: (value) {
        setState(() {
          _useDynamicColor = value;
        });
      },
    );
  }

  Widget _buildIntroText() {
    final text = _supportsAndroidDynamicColor
        ? '下方颜色用于 Android 动态色不可用时的回退主题，也会用于 iOS、macOS 等设备。'
        : '当前平台不支持系统动态取色，请手动选择主题色。';

    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }

  Widget _buildSeedColorGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _seedColors.map((hex) {
        final isSelected = _seedColorHex == hex;
        final color = ColorUtils.fromHex(hex);
        return GestureDetector(
          onTap: () {
            setState(() {
              _seedColorHex = hex;
            });
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _save,
      child: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('保存外观设置'),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(appearanceConfigProvider.notifier)
          .save(
            AppearanceConfig(
              useDynamicColor: _useDynamicColor,
              seedColorHex: _seedColorHex,
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('外观设置已保存')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
