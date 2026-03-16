import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/core/utils/category_matcher.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/models/parse_result.dart';
import 'package:runway_ddl/data/repositories/category_repository.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';
import 'package:runway_ddl/presentation/providers/items_provider.dart';
import 'package:runway_ddl/presentation/pages/add_item/widgets/quick_input_tab.dart';
import 'package:runway_ddl/presentation/pages/add_item/widgets/image_input_tab.dart';
import 'package:runway_ddl/presentation/widgets/add_category_dialog.dart';

class AddItemPage extends ConsumerStatefulWidget {
  const AddItemPage({super.key});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _quickInputTabController;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = app_utils.DateUtils.today();
  String? _selectedTime;
  String _selectedCategoryId = 'uncategorized';
  ItemPriority _selectedPriority = ItemPriority.medium;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _quickInputTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _quickInputTabController.dispose();
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
          AnimatedBuilder(
            animation: _mainTabController,
            builder: (context, child) {
              if (_mainTabController.index == 0) {
                return TextButton(
                  onPressed: _isLoading ? null : _createItem,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('创建'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMainTabBar(),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildManualInputTab(categoriesAsync),
                _buildQuickInputTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: TabBar(
        controller: _mainTabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        tabs: const [
          Tab(text: '手动添加'),
          Tab(text: '快捷添加'),
        ],
      ),
    );
  }

  Widget _buildManualInputTab(AsyncValue<List<Category>> categoriesAsync) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTitleField(),
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
          _buildDescriptionField(),
        ],
      ),
    );
  }

  Widget _buildQuickInputTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: TabBar(
            controller: _quickInputTabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(text: '文本输入'),
              Tab(text: '图片输入'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _quickInputTabController,
            children: [
              QuickInputTab(onParsed: _createItemFromParseResult),
              ImageInputTab(onParsed: _createItemFromParseResultWithImage),
            ],
          ),
        ),
      ],
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
    final selectedCategory = _findCategoryById(categories, _selectedCategoryId);

    return InkWell(
      onTap: () => _showCategorySelector(categories),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '分类 *',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _resolveCategoryColor(selectedCategory),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedCategory?.name ?? '未分类',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Category? _findCategoryById(List<Category> categories, String categoryId) {
    try {
      return categories.firstWhere((category) => category.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  Color _resolveCategoryColor(Category? category) {
    try {
      final colorHex = category?.color.replaceFirst('#', '') ?? '9E9E9E';
      return Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      return AppColors.uncategorized;
    }
  }

  Future<void> _showCategorySelector(List<Category> categories) async {
    final selectedValue = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '选择分类',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final category in categories)
                      ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _resolveCategoryColor(category),
                          ),
                        ),
                        title: Text(category.name),
                        trailing: category.id == _selectedCategoryId
                            ? Icon(
                                Icons.check,
                                color: colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, category.id),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('新增类型'),
                      onTap: () => Navigator.pop(context, '__add_category__'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedValue == null) {
      return;
    }

    if (selectedValue == '__add_category__') {
      await _showAddCategoryDialog();
      return;
    }

    setState(() {
      _selectedCategoryId = selectedValue;
    });
  }

  Future<void> _showAddCategoryDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AddCategoryDialog(
        onConfirm: (name, color) async {
          try {
            final category = await ref
                .read(categoriesProvider.notifier)
                .createCategory(name, color);
            if (!dialogContext.mounted || !mounted) {
              return;
            }

            Navigator.pop(dialogContext);
            setState(() {
              _selectedCategoryId = category.id;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已新增分类「${category.name}」')),
            );
          } on CategoryNameExistsException {
            if (!dialogContext.mounted) {
              return;
            }
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(content: Text('分类名称已存在')),
            );
          } catch (e) {
            if (!dialogContext.mounted) {
              return;
            }
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text('创建失败: $e')),
            );
          }
        },
      ),
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
      await ref
          .read(itemsProvider.notifier)
          .createItem(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createItemFromParseResult(ParseResult result) async {
    try {
      await ref
          .read(itemsProvider.notifier)
          .createItem(
            title: result.title ?? '未命名事项',
            dueDate: result.date ?? app_utils.DateUtils.today(),
            categoryId: _resolveCategoryId(result),
            dueTime: result.time,
            priority: result.priority,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    }
  }

  Future<void> _createItemFromParseResultWithImage(
    ParseResult result,
    String? imagePath,
  ) async {
    try {
      await ref
          .read(itemsProvider.notifier)
          .createItem(
            title: result.title ?? '未命名事项',
            dueDate: result.date ?? app_utils.DateUtils.today(),
            categoryId: _resolveCategoryId(result),
            dueTime: result.time,
            priority: result.priority,
            imagePath: imagePath,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    }
  }

  String _getRecommendedCategoryId(String? hint) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final category = CategoryMatcher.findRecommendedCategory(hint, categories);
    return category?.id ?? 'uncategorized';
  }

  String _resolveCategoryId(ParseResult result) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    if (result.categoryId != null &&
        categories.any((category) => category.id == result.categoryId)) {
      return result.categoryId!;
    }
    return _getRecommendedCategoryId(result.categoryHint);
  }
}
