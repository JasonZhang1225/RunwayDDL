import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runway_ddl/data/models/parse_result.dart';
import 'package:runway_ddl/presentation/providers/ai_provider.dart';
import 'package:runway_ddl/presentation/pages/add_item/widgets/parse_result_preview.dart';

class QuickInputTab extends ConsumerStatefulWidget {
  final Function(ParseResult result) onParsed;
  final VoidCallback? onCancel;

  const QuickInputTab({super.key, required this.onParsed, this.onCancel});

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
          if (_parseResult != null && !_parseResult!.success)
            _buildErrorMessage(_parseResult!.errorMessage),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '输入任务描述：',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '例如：明天交英语作业',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildParseButton(AsyncValue<ParseResult> parseState) {
    return ElevatedButton(
      onPressed: parseState.isLoading ? null : _parseInput,
      child: const Text('解析', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildLoadingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('正在解析...', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(Object? error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error?.toString() ?? '解析失败，请重试',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _parseInput() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入任务描述')));
      return;
    }

    final result = await ref.read(textParserProvider.notifier).parse(input);
    if (!mounted) {
      return;
    }

    setState(() {
      _parseResult = result;
    });
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
