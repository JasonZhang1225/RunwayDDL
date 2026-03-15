import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/data/models/parse_result.dart';
import 'package:runway_ddl/presentation/providers/ai_provider.dart';
import 'package:runway_ddl/presentation/pages/add_item/widgets/parse_result_preview.dart';

class QuickInputTab extends ConsumerStatefulWidget {
  final Function(ParseResult result) onParsed;
  final VoidCallback? onCancel;

  const QuickInputTab({
    super.key,
    required this.onParsed,
    this.onCancel,
  });

  @override
  ConsumerState<QuickInputTab> createState() => _QuickInputTabState();
}

class _QuickInputTabState extends ConsumerState<QuickInputTab> {
  final _textController = TextEditingController();
  ParseResult? _parseResult;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parseState = ref.watch(textParserProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputField(),
          const SizedBox(height: 16),
          _buildParseButton(parseState),
          const SizedBox(height: 16),
          if (parseState.isLoading) _buildLoadingIndicator(),
          if (parseState.hasError) _buildErrorMessage(parseState.error),
          if (_parseResult != null && _parseResult!.success)
            Expanded(
              child: ParseResultPreview(
                result: _parseResult!,
                onResultChanged: _onResultChanged,
                onConfirm: _onConfirm,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '输入任务描述：',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '例如：明天交英语作业',
            hintStyle: TextStyle(color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildParseButton(AsyncValue<ParseResult> parseState) {
    return ElevatedButton(
      onPressed: parseState.isLoading ? null : _parseInput,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        '解析',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '正在解析...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(Object? error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.overdueBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.overdue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error?.toString() ?? '解析失败，请重试',
              style: const TextStyle(color: AppColors.overdue),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _parseInput() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务描述')),
      );
      return;
    }

    final result = await ref.read(textParserProvider.notifier).parse(input);
    if (result.success && mounted) {
      setState(() {
        _parseResult = result;
      });
    }
  }

  void _onResultChanged(ParseResult result) {
    setState(() {
      _parseResult = result;
    });
  }

  void _onConfirm() {
    if (_parseResult != null) {
      widget.onParsed(_parseResult!);
    }
  }
}
