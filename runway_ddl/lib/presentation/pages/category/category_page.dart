import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/repositories/category_repository.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';
import 'package:runway_ddl/presentation/providers/items_provider.dart';
import 'package:runway_ddl/presentation/widgets/add_category_dialog.dart';

class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoryList(context, ref, categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('暂无分类'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          onEdit: category.canEdit
              ? () => _showEditCategoryDialog(context, ref, category)
              : null,
          onDelete: category.canDelete
              ? () => _showDeleteConfirmation(context, ref, category)
              : null,
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        onConfirm: (name, color) async {
          try {
            await ref.read(categoriesProvider.notifier).createCategory(name, color);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分类创建成功')),
              );
            }
          } on CategoryNameExistsException {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分类名称已存在')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('创建失败: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (context) => _EditCategoryDialog(
        category: category,
        onConfirm: (name, color) async {
          try {
            await ref
                .read(categoriesProvider.notifier)
                .updateCategory(category.id, name: name, color: color);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分类更新成功')),
              );
            }
          } on CategoryNameExistsException {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分类名称已存在')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('更新失败: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类「${category.name}」吗？\n该分类下的事项将迁移到"未分类"。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(itemRepositoryProvider).migrateToUncategorized(category.id);
                await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
                ref.invalidate(itemsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('分类删除成功')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryCard({
    required this.category,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color categoryColor;
    try {
      final colorHex = category.color.replaceFirst('#', '');
      categoryColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      categoryColor = AppColors.uncategorized;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (category.isSystem) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '系统',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                color: colorScheme.onSurfaceVariant,
              ),
            if (category.isSystem)
              IconButton(
                icon: Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: null,
              ),
          ],
        ),
      ),
    );
  }
}

class _EditCategoryDialog extends StatefulWidget {
  final Category category;
  final Future<void> Function(String name, String color) onConfirm;

  const _EditCategoryDialog({
    required this.category,
    required this.onConfirm,
  });

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late final TextEditingController _controller;
  late String _selectedColor;
  bool _isLoading = false;

  final _colors = [
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
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category.name);
    _selectedColor = widget.category.color;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑分类'),
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
              Color c;
              try {
                final colorHex = color.replaceFirst('#', '');
                c = Color(int.parse('FF$colorHex', radix: 16));
              } catch (_) {
                c = AppColors.uncategorized;
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
                    color: c,
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

                  await widget.onConfirm(_controller.text.trim(), _selectedColor);
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
