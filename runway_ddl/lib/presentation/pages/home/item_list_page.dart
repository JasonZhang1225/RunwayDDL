import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/models/item_priority_extension.dart';
import 'package:runway_ddl/presentation/providers/item_list_provider.dart';

class ItemListPage extends ConsumerStatefulWidget {
  const ItemListPage({super.key});

  @override
  ConsumerState<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends ConsumerState<ItemListPage> {
  ItemListFilter _filter = ItemListFilter.all;

  @override
  Widget build(BuildContext context) {
    final listData = ref.watch(itemListDataProvider);
    final tabs = [null, ...listData.categories];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('事项列表'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: '全部类别'),
              ...listData.categories.map((category) => Tab(text: category.name)),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: TabBarView(
                children: tabs.map((category) {
                  final items = category == null
                      ? listData.allItems
                      : listData.itemsByCategory[category.id] ?? const <Item>[];
                  return _ItemListTab(
                    items: applyItemListFilter(items, _filter),
                    emptyLabel: _buildEmptyLabel(category),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<ItemListFilter>(
          segments: const [
            ButtonSegment(value: ItemListFilter.all, label: Text('全部')),
            ButtonSegment(value: ItemListFilter.overdue, label: Text('逾期')),
            ButtonSegment(value: ItemListFilter.history, label: Text('历史完成')),
          ],
          selected: {_filter},
          onSelectionChanged: (selection) {
            setState(() {
              _filter = selection.first;
            });
          },
        ),
      ),
    );
  }

  String _buildEmptyLabel(Category? category) {
    final categoryLabel = category == null ? '全部类别' : category.name;
    switch (_filter) {
      case ItemListFilter.all:
        return '$categoryLabel 暂无事项';
      case ItemListFilter.overdue:
        return '$categoryLabel 暂无逾期事项';
      case ItemListFilter.history:
        return '$categoryLabel 暂无历史完成';
    }
  }
}

class _ItemListTab extends StatelessWidget {
  final List<Item> items;
  final String emptyLabel;

  const _ItemListTab({required this.items, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Text(
          emptyLabel,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _ItemListCard(item: items[index]);
      },
    );
  }
}

class _ItemListCard extends StatelessWidget {
  final Item item;

  const _ItemListCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dueDate = app_utils.DateUtils.formatDateWithWeekday(item.dueDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/items/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: item.priority.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: item.status == ItemStatus.completed
                            ? colorScheme.onSurface.withValues(alpha: 0.55)
                            : colorScheme.onSurface,
                        decoration: item.status == ItemStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  _StatusChip(item: item),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _MetaText(
                    icon: Icons.calendar_today_outlined,
                    label: dueDate,
                  ),
                  if (item.dueTime != null)
                    _MetaText(
                      icon: Icons.access_time,
                      label: item.dueTime!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Item item;

  const _StatusChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOverdue =
        item.status == ItemStatus.pending && item.dueDate.isBefore(app_utils.DateUtils.today());

    final (label, background, foreground) = switch ((item.status, isOverdue)) {
      (ItemStatus.completed, _) => ('已完成', colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
      (_, true) => ('逾期', colorScheme.errorContainer, colorScheme.onErrorContainer),
      _ => ('待完成', colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaText({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
