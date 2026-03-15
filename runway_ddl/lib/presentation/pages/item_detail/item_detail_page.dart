import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/models/item_priority_extension.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';
import 'package:runway_ddl/presentation/providers/image_picker_provider.dart';
import 'package:runway_ddl/presentation/providers/items_provider.dart';

class ItemDetailPage extends ConsumerStatefulWidget {
  final String itemId;

  const ItemDetailPage({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends ConsumerState<ItemDetailPage> {
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedCategoryId;
  ItemPriority? _selectedPriority;
  String? _selectedImagePath;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(itemByIdProvider(widget.itemId));

    if (item == null) {
      return _buildNotFound();
    }
    return _buildContent(context, item);
  }

  Widget _buildNotFound() {
    return Scaffold(
      appBar: AppBar(title: const Text('事项详情')),
      body: const Center(child: Text('事项不存在')),
    );
  }

  Widget _buildContent(BuildContext context, Item item) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑事项' : '事项详情'),
        actions: [
          if (!_isEditing)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('编辑'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.overdue),
                      SizedBox(width: 8),
                      Text('删除', style: TextStyle(color: AppColors.overdue)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isEditing ? _buildEditMode(item) : _buildViewMode(item),
      bottomNavigationBar: _isEditing ? null : _buildBottomActions(item),
    );
  }

  Widget _buildViewMode(Item item) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final category = categoriesAsync.valueOrNull?.firstWhere(
      (c) => c.id == item.categoryId,
      orElse: () => Category(
        id: 'unknown',
        name: '未知分类',
        color: '#9E9E9E',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusIndicator(item),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: item.status == ItemStatus.completed
                  ? AppColors.textPrimary.withOpacity(0.5)
                  : AppColors.textPrimary,
              decoration: item.status == ItemStatus.completed
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetaInfo(item, category),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const Divider(height: 32),
            const Text(
              '描述',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(item.description!, style: const TextStyle(fontSize: 16)),
          ],
          if (item.imagePath != null && item.imagePath!.isNotEmpty) ...[
            const Divider(height: 32),
            const Text(
              '图片附件',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImagePreview(item.imagePath!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(item.imagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(child: Text('图片加载失败')),
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 32),
          _buildTimestamps(item),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Item item) {
    final (text, color, bgColor) = switch (item.status) {
      ItemStatus.pending => ('待完成', AppColors.primary, AppColors.primaryLight),
      ItemStatus.completed => (
        '已完成',
        AppColors.completed,
        AppColors.completedBackground,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaInfo(Item item, Category? category) {
    Color categoryColor = AppColors.uncategorized;
    if (category != null) {
      try {
        final colorHex = category.color.replaceFirst('#', '');
        categoryColor = Color(int.parse('FF$colorHex', radix: 16));
      } catch (_) {}
    }

    final priorityLabel = item.priority.label;
    final priorityColor = item.priority.color;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildMetaItem(
          icon: Icons.category_outlined,
          label: category?.name ?? '未分类',
          color: categoryColor,
        ),
        _buildMetaItem(
          icon: Icons.calendar_today,
          label: app_utils.DateUtils.formatDateShort(item.dueDate),
        ),
        if (item.dueTime != null)
          _buildMetaItem(icon: Icons.access_time, label: item.dueTime!),
        _buildMetaItem(
          icon: Icons.flag_outlined,
          label: '$priorityLabel优先级',
          color: priorityColor,
        ),
      ],
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamps(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '创建时间: ${_formatDateTime(item.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          '最后更新: ${_formatDateTime(item.updatedAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (item.completedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            '完成时间: ${_formatDateTime(item.completedAt!)}',
            style: const TextStyle(fontSize: 12, color: AppColors.completed),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showImagePreview(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }

  Widget _buildEditMode(Item item) {
    _initEditControllers(item);

    final categoriesAsync = ref.watch(categoriesProvider);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题 *',
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
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (categories) => _buildCategoryDropdown(categories),
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('加载分类失败'),
          ),
          const SizedBox(height: 16),
          _buildDateField(),
          const SizedBox(height: 16),
          _buildTimeField(),
          const SizedBox(height: 16),
          _buildPrioritySelector(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 16),
          _buildImageSelector(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _initEditControllers(Item item) {
    if (_titleController.text.isEmpty) {
      _titleController.text = item.title;
      _descriptionController.text = item.description ?? '';
      _selectedDate ??= item.dueDate;
      _selectedTime ??= item.dueTime;
      _selectedCategoryId ??= item.categoryId;
      _selectedPriority ??= item.priority;
      _selectedImagePath ??= item.imagePath;
    }
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
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
              _selectedDate != null
                  ? app_utils.DateUtils.formatDateWithWeekday(_selectedDate!)
                  : '选择日期',
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
          final label = priority.label;
          final color = priority.color;

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

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '图片附件',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_selectedImagePath!),
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 100,
                color: Colors.grey[200],
                child: const Center(child: Text('图片加载失败')),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('更换图片'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImagePath = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('删除图片'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.overdue,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('添加图片'),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    final imageService = ref.read(imagePickerProvider);
    final imagePath = await imageService.pickFromGallery();
    if (imagePath != null) {
      setState(() {
        _selectedImagePath = imagePath;
      });
    }
  }

  Widget _buildBottomActions(Item item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _toggleStatus(item),
                icon: Icon(
                  item.status == ItemStatus.completed
                      ? Icons.replay
                      : Icons.check,
                ),
                label: Text(
                  item.status == ItemStatus.completed ? '取消完成' : '标记完成',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.status == ItemStatus.completed
                      ? AppColors.textSecondary
                      : AppColors.completed,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Item item) {
    switch (action) {
      case 'edit':
        setState(() {
          _isEditing = true;
        });
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _showDeleteConfirmation(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${item.title}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.overdue),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(Item item) async {
    await ref.read(itemsProvider.notifier).deleteItem(item.id);
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _toggleStatus(Item item) async {
    await ref.read(itemsProvider.notifier).toggleStatus(item.id);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择截止日期')));
      return;
    }

    final item = ref.read(itemByIdProvider(widget.itemId));
    if (item == null) return;

    final oldImagePath = item.imagePath;

    final updatedItem = Item(
      id: item.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryId: _selectedCategoryId ?? 'uncategorized',
      dueDate: _selectedDate!,
      dueTime: _selectedTime,
      priority: _selectedPriority ?? ItemPriority.medium,
      status: item.status,
      imagePath: _selectedImagePath,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      completedAt: item.completedAt,
    );

    await ref
        .read(itemsProvider.notifier)
        .updateItem(updatedItem, oldImagePath: oldImagePath);

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存成功')));
    }
  }
}
