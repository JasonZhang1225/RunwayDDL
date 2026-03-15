
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/presentation/providers/api_config_provider.dart';

class ApiConfigPage extends ConsumerStatefulWidget {
  const ApiConfigPage({super.key});

  @override
  ConsumerState<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends ConsumerState<ApiConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController(
    text: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
  );
  final _textModelController = TextEditingController(
    text: 'qwen-plus',
  );
  final _imageModelController = TextEditingController(
    text: 'qwen-vl-plus',
  );
  bool _isLoading = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final config = ref.read(apiConfigNotifierProvider);
    config.whenData((data) {
      if (data != null && data.apiKey.isNotEmpty) {
        _apiKeyController.text = data.apiKey;
      }
      if (data != null && data.baseUrl.isNotEmpty) {
        _baseUrlController.text = data.baseUrl;
      }
      if (data != null && data.textModel.isNotEmpty) {
        _textModelController.text = data.textModel;
      }
      if (data != null && data.imageModel.isNotEmpty) {
        _imageModelController.text = data.imageModel;
      }
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _textModelController.dispose();
    _imageModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 配置'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildBaseUrlField(),
            const SizedBox(height: 16),
            _buildApiKeyField(),
            const SizedBox(height: 16),
            _buildTextModelField(),
            const SizedBox(height: 16),
            _buildImageModelField(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            _buildTestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.primaryLight.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '如何获取 API Key',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. 访问阿里云百炼控制台：https://bailian.console.aliyun.com\n'
              '2. 登录并进入「模型应用」> 「API-KEY 管理」\n'
              '3. 创建新的 API Key 或复制已有 Key\n'
              '4. 粘贴到下方输入框',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '支持模型：qwen-plus（文本）、qwen-vl-plus（图像）',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseUrlField() {
    return TextFormField(
      controller: _baseUrlController,
      decoration: const InputDecoration(
        labelText: 'API Base URL',
        hintText: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        prefixIcon: Icon(Icons.link),
        helperText: '通义千问 API 地址，一般无需修改',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入 API 地址';
        }
        if (!value.startsWith('http')) {
          return 'URL 必须以 http 或 https 开头';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildApiKeyField() {
    return TextFormField(
      controller: _apiKeyController,
      obscureText: _obscureApiKey,
      decoration: InputDecoration(
        labelText: 'API Key',
        hintText: '请输入您的 API Key',
        prefixIcon: const Icon(Icons.key),
        helperText: 'API Key 将加密存储在本地',
        suffixIcon: IconButton(
          icon: Icon(
            _obscureApiKey ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureApiKey = !_obscureApiKey;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入 API Key';
        }
        if (value.length < 10) {
          return 'API Key 格式不正确';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildTextModelField() {
    return TextFormField(
      controller: _textModelController,
      decoration: const InputDecoration(
        labelText: '文本解析模型',
        hintText: 'qwen-plus',
        prefixIcon: Icon(Icons.text_fields),
        helperText: '用于自然语言文本解析，推荐：qwen-plus, qwen-turbo, qwen-max',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入模型名称';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildImageModelField() {
    return TextFormField(
      controller: _imageModelController,
      decoration: const InputDecoration(
        labelText: '图像解析模型',
        hintText: 'qwen-vl-plus',
        prefixIcon: Icon(Icons.image),
        helperText: '用于图片 OCR 和解析，推荐：qwen-vl-plus, qwen-vl-max',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入模型名称';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveConfig,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              '保存配置',
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  Widget _buildTestButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : _testConnection,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        '测试连接',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(apiConfigNotifierProvider.notifier).saveConfig(
            baseUrl: _baseUrlController.text,
            apiKey: _apiKeyController.text,
            textModel: _textModelController.text,
            imageModel: _imageModelController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置已保存'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(apiConfigNotifierProvider.notifier).testConnection(
            baseUrl: _baseUrlController.text,
            apiKey: _apiKeyController.text,
            model: _textModelController.text,
          );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: result.success ? const Text('测试成功') : const Text('测试失败'),
            content: Text(result.errorMessage ?? 'API 连接正常'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试失败：$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
