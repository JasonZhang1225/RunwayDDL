import 'package:flutter/material.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';

class AddCategoryDialog extends StatefulWidget {
  final Future<void> Function(String name, String color) onConfirm;

  const AddCategoryDialog({super.key, required this.onConfirm});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _controller = TextEditingController();
  String _selectedColor = '#2196F3';
  bool _isLoading = false;

  final _colors = const [
    '#F44336',
    '#E91E63',
    '#9C27B0',
    '#673AB7',
    '#3F51B5',
    '#2196F3',
    '#03A9F4',
    '#00BCD4',
    '#009688',
    '#4CAF50',
    '#8BC34A',
    '#CDDC39',
    '#FFC107',
    '#FF9800',
    '#FF5722',
    '#795548',
    '#9E9E9E',
    '#607D8B',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加分类'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '分类名称',
              hintText: '请输入分类名称',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '选择颜色',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              final isSelected = _selectedColor == color;
              Color resolvedColor;
              try {
                final colorHex = color.replaceFirst('#', '');
                resolvedColor = Color(int.parse('FF$colorHex', radix: 16));
              } catch (_) {
                resolvedColor = AppColors.uncategorized;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: resolvedColor,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_controller.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入分类名称')),
                    );
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });

                  await widget.onConfirm(
                    _controller.text.trim(),
                    _selectedColor,
                  );
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }
}
