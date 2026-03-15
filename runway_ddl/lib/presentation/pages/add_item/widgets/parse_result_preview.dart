import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/models/parse_result.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';

class ParseResultPreview extends ConsumerStatefulWidget {
  final ParseResult result;
  final Function(ParseResult) onResultChanged;
  final VoidCallback onConfirm;

  const ParseResultPreview({
    super.key,
    required this.result,
    required this.onResultChanged,
    required this.onConfirm,
  });

  @override
  ConsumerState<ParseResultPreview> createState() => _ParseResultPreviewState();
}

class _ParseResultPreviewState extends ConsumerState<ParseResultPreview> {
  late TextEditingController _titleController;
  late DateTime? _selectedDate;
  late String? _selectedTime;
  late String? _categoryHint;
  late ItemPriority _selectedPriority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.result.title ?? '');
    _selectedDate = widget.result.date;
    _selectedTime = widget.result.time;
    _categoryHint = widget.result.categoryHint;
    _selectedPriority = widget.result.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('解析结果'),
          const SizedBox(height: 12),
          _buildTitleField(),
          const SizedBox(height: 12),
          _buildDateField(),
          const SizedBox(height: 12),
          _buildTimeField(),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (categories) => _buildCategoryDropdown(categories),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          _buildPrioritySelector(),
          const SizedBox(height: 24),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.divider)),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: '标题',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (value) => _updateResult(),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '日期',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate != null
                  ? app_utils.DateUtils.formatDateWithWeekday(_selectedDate!)
                  : '--:--',
              style: TextStyle(
                fontSize: 16,
                color: _selectedDate != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
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
      _updateResult();
    }
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '时间',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTime ?? '--:--',
              style: TextStyle(
                fontSize: 16,
                color: _selectedTime != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
            ),
            if (_selectedTime != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTime = null;
                  });
                  _updateResult();
                },
                child: const Icon(Icons.clear, size: 20),
              )
            else
              const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime != null
          ? TimeOfDay(
              hour: int.parse(_selectedTime!.split(':')[0]),
              minute: int.parse(_selectedTime!.split(':')[1]),
            )
          : const TimeOfDay(hour: 12, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      _updateResult();
    }
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    String? selectedCategoryId;
    if (_categoryHint != null) {
      final matchedCategory = categories
          .where(
            (c) =>
                c.name.toLowerCase().contains(_categoryHint!.toLowerCase()) ||
                _categoryHint!.toLowerCase().contains(c.name.toLowerCase()),
          )
          .firstOrNull;
      if (matchedCategory != null) {
        selectedCategoryId = matchedCategory.id;
      }
    }
    selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedCategoryId,
      decoration: InputDecoration(
        labelText: '分类',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
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
        if (value != null) {
          final category = categories.firstWhere((c) => c.id == value);
          setState(() {
            _categoryHint = category.name;
          });
          _updateResult();
        }
      },
    );
  }

  Widget _buildPrioritySelector() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '优先级',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              _updateResult();
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
                      _updateResult();
                    }
                  },
                  activeColor: color,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textSecondary,
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
      onPressed: widget.onConfirm,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('确认添加', style: TextStyle(fontSize: 16)),
    );
  }

  void _updateResult() {
    final updatedResult = widget.result.copyWith(
      title: _titleController.text,
      date: _selectedDate,
      time: _selectedTime,
      categoryHint: _categoryHint,
      priority: _selectedPriority,
    );
    widget.onResultChanged(updatedResult);
  }
}
