import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/core/utils/category_matcher.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/models/parse_result.dart';
import 'package:runway_ddl/presentation/providers/ai_provider.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';
import 'package:runway_ddl/presentation/providers/image_picker_provider.dart';

class ImageInputTab extends ConsumerStatefulWidget {
  final Function(ParseResult result, String? imagePath) onParsed;
  final VoidCallback? onCancel;

  const ImageInputTab({super.key, required this.onParsed, this.onCancel});

  @override
  ConsumerState<ImageInputTab> createState() => _ImageInputTabState();
}

class _ImageInputTabState extends ConsumerState<ImageInputTab> {
  String? _imagePath;
  ParseResult? _parseResult;
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedCategoryId;
  ItemPriority _selectedPriority = ItemPriority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final service = ref.read(imagePickerProvider);
      final path = await service.pickFromGallery();
      if (path != null && mounted) {
        setState(() {
          _imagePath = path;
          _parseResult = null;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
    }
  }

  Future<void> _pickFromCamera() async {
    if (Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('macOS 当前不支持直接拍照，请使用“选择图片”')),
      );
      return;
    }

    try {
      final service = ref.read(imagePickerProvider);
      final path = await service.pickFromCamera();
      if (path != null && mounted) {
        setState(() {
          _imagePath = path;
          _parseResult = null;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('拍照失败: $e')));
    }
  }

  Future<void> _parseImage() async {
    if (_imagePath == null) return;

    final result = await ref
        .read(imageParserProvider.notifier)
        .parse(_imagePath!);
    if (!mounted) {
      return;
    }

    setState(() {
      _parseResult = result;
      if (result.success && result.title != null) {
        _titleController.text = result.title!;
      }
      if (result.success && result.date != null) {
        _selectedDate = result.date;
      }
      if (result.success) {
        _selectedPriority = result.priority;
        final categories = ref.read(categoriesProvider).valueOrNull ?? [];
        _selectedCategoryId =
            result.categoryId ??
            CategoryMatcher.findRecommendedCategory(
              result.categoryHint,
              categories,
            )?.id;
      }
    });
  }

  void _confirmAdd() {
    if (_parseResult == null) return;

    final result = _parseResult!.copyWith(
      title: _titleController.text.isNotEmpty
          ? _titleController.text
          : _parseResult!.title,
      date: _selectedDate,
      categoryId: _selectedCategoryId,
      priority: _selectedPriority,
    );

    widget.onParsed(result, _imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final parseState = ref.watch(imageParserProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSourceButtons(),
          const SizedBox(height: 16),
          _buildImagePreview(),
          const SizedBox(height: 16),
          _buildParseButton(parseState),
          const SizedBox(height: 16),
          if (_parseResult != null && !_parseResult!.success) ...[
            _buildErrorCard(_parseResult!.errorMessage ?? '图片解析失败，请重试'),
          ],
          if (_parseResult != null && _parseResult!.success) ...[
            const Divider(),
            const SizedBox(height: 8),
            _buildParseResultSection(categoriesAsync),
            const SizedBox(height: 16),
            _buildConfirmButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSourceButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('选择图片'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('拍照'),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_imagePath == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                '请选择或拍摄图片',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(_imagePath!),
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildParseButton(AsyncValue<ParseResult> parseState) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: _imagePath == null || parseState.isLoading
          ? null
          : _parseImage,
      icon: parseState.isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(parseState.isLoading ? '解析中...' : '解析图片'),
    );
  }

  Widget _buildParseResultSection(AsyncValue<List<Category>> categoriesAsync) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('解析结果', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_parseResult!.ocrText != null) ...[
          _buildOcrTextCard(),
          const SizedBox(height: 12),
        ],
        _buildTitleField(),
        const SizedBox(height: 12),
        _buildDateField(),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) => _buildCategoryDropdown(categories),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        _buildPrioritySelector(),
      ],
    );
  }

  Widget _buildOcrTextCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.text_fields,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '识别文字：',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _parseResult!.ocrText!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
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
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '标题',
        prefixIcon: Icon(Icons.title),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDateField() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '日期',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate != null
                  ? app_utils.DateUtils.formatDateWithWeekday(_selectedDate!)
                  : '未设置',
              style: TextStyle(
                fontSize: 16,
                color: _selectedDate != null
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    final selectedCategoryId =
        _selectedCategoryId ??
        CategoryMatcher.findRecommendedCategory(
          _parseResult?.categoryHint,
          categories,
        )?.id;

    return DropdownButtonFormField<String>(
      initialValue: selectedCategoryId,
      decoration: const InputDecoration(
        labelText: '分类',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      hint: const Text('选择分类'),
      items: categories.map((category) {
        Color categoryColor;
        try {
          final colorHex = category.color.replaceFirst('#', '');
          categoryColor = Color(int.parse('FF$colorHex', radix: 16));
        } catch (_) {
          categoryColor = AppColors.uncategorized;
        }

        return DropdownMenuItem(
          value: category.id,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
    );
  }

  Widget _buildPrioritySelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '优先级',
        prefixIcon: Icon(Icons.flag_outlined),
        border: OutlineInputBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ItemPriority.values.map((priority) {
          final isSelected = _selectedPriority == priority;
          final (label, color) = _getPriorityInfo(priority);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPriority = priority;
              });
            },
            child: Row(
              children: [
                Radio<ItemPriority>(
                  value: priority,
                  groupValue: _selectedPriority,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                  activeColor: color,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  (String, Color) _getPriorityInfo(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return ('高', AppColors.highPriority);
      case ItemPriority.medium:
        return ('中', AppColors.mediumPriority);
      case ItemPriority.low:
        return ('低', AppColors.lowPriority);
    }
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _parseResult != null ? _confirmAdd : null,
      child: const Text('确认添加'),
    );
  }
}
