import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';
import 'package:runway_ddl/presentation/providers/items_provider.dart';

class AddItemPage extends ConsumerStatefulWidget {
  const AddItemPage({super.key});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = app_utils.DateUtils.today();
  String? _selectedTime;
  String _selectedCategoryId = 'uncategorized';
  ItemPriority _selectedPriority = ItemPriority.medium;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加事项'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createItem,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('创建'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) => _buildCategoryDropdown(categories),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('加载分类失败'),
            ),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTimeField(),
            const SizedBox(height: 16),
            _buildPrioritySelector(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '标题 *',
        hintText: '请输入任务标题',
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入标题';
        }
        if (value.trim().length > 100) {
          return '标题不能超过100个字符';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: '分类 *',
        prefixIcon: Icon(Icons.category_outlined),
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
          setState(() {
            _selectedCategoryId = value;
          });
        }
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '截止日期 *',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              app_utils.DateUtils.formatDateWithWeekday(_selectedDate),
              style: const TextStyle(fontSize: 16),
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
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '截止时间（可选）',
          prefixIcon: Icon(Icons.access_time),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTime ?? '不设置',
              style: TextStyle(
                fontSize: 16,
                color: _selectedTime != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            if (_selectedTime != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTime = null;
                  });
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
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildPrioritySelector() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '优先级',
        prefixIcon: Icon(Icons.flag_outlined),
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
                    color: isSelected ? color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: '描述（可选）',
        hintText: '补充说明...',
        prefixIcon: Icon(Icons.notes_outlined),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      maxLength: 500,
      validator: (value) {
        if (value != null && value.length > 500) {
          return '描述不能超过500个字符';
        }
        return null;
      },
    );
  }

  Future<void> _createItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(itemsProvider.notifier).createItem(
            title: _titleController.text,
            dueDate: _selectedDate,
            categoryId: _selectedCategoryId,
            dueTime: _selectedTime,
            priority: _selectedPriority,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
