import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/data/models/ai_config.dart';
import 'package:runway_ddl/presentation/providers/ai_provider.dart';

class AIConfigPage extends ConsumerStatefulWidget {
  const AIConfigPage({super.key});

  @override
  ConsumerState<AIConfigPage> createState() => _AIConfigPageState();
}

class _AIConfigPageState extends ConsumerState<AIConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController(
    text: AIConfig.defaultBaseUrl,
  );
  final _modelController = TextEditingController(text: AIConfig.defaultModel);
  bool _obscureApiKey = true;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aIConfigNotifierProvider);

    if (!_initialized) {
      _hydrateForm(config);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI 配置')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildApiKeyField(),
            const SizedBox(height: 16),
            _buildBaseUrlField(),
            const SizedBox(height: 16),
            _buildModelField(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                '阿里云百炼默认配置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'API Key：在百炼控制台创建 API-KEY 后填入本页。',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Base URL：默认使用 DashScope OpenAI 兼容模式地址。',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '模型：默认 qwen3.5-flash，可同时处理文本和图片解析。',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField() {
    return TextFormField(
      controller: _apiKeyController,
      obscureText: _obscureApiKey,
      decoration: InputDecoration(
        labelText: 'API Key',
        hintText: '请输入阿里云百炼 API Key',
        prefixIcon: const Icon(Icons.key_outlined),
        helperText: '必填。本地保存后，文本解析和图片解析都会使用该 Key。',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureApiKey = !_obscureApiKey;
            });
          },
          icon: Icon(
            _obscureApiKey
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入 API Key';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildBaseUrlField() {
    return TextFormField(
      controller: _baseUrlController,
      decoration: const InputDecoration(
        labelText: 'Base URL',
        hintText: AIConfig.defaultBaseUrl,
        prefixIcon: Icon(Icons.link_outlined),
        helperText: '默认值一般无需修改。',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return '请输入 Base URL';
        }
        if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
          return 'Base URL 必须以 http:// 或 https:// 开头';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildModelField() {
    return TextFormField(
      controller: _modelController,
      decoration: const InputDecoration(
        labelText: '模型',
        hintText: AIConfig.defaultModel,
        prefixIcon: Icon(Icons.smart_toy_outlined),
        helperText: '单模型配置，同时用于文本和图片解析。',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入模型名称';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveConfig(),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveConfig,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('保存配置'),
    );
  }

  void _hydrateForm(AIConfig config) {
    _apiKeyController.text = config.apiKey;
    _baseUrlController.text = config.baseUrl;
    _modelController.text = config.model;
    _initialized = true;
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(aIConfigNotifierProvider.notifier)
          .saveConfig(
            AIConfig(
              apiKey: _apiKeyController.text,
              baseUrl: _baseUrlController.text,
              model: _modelController.text,
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI 配置已保存'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
