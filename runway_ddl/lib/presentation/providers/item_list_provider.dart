import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';
import 'package:runway_ddl/presentation/providers/items_provider.dart';

part 'item_list_provider.g.dart';

enum ItemListFilter { all, overdue, history }

class ItemListData {
  final List<Category> categories;
  final List<Item> allItems;
  final Map<String, List<Item>> itemsByCategory;

  const ItemListData({
    required this.categories,
    required this.allItems,
    required this.itemsByCategory,
  });
}

@riverpod
ItemListData itemListData(ItemListDataRef ref) {
  final List<Category> categories =
      ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
  final items = <Item>[
    ...(ref.watch(itemsProvider).valueOrNull ?? const <Item>[]),
  ]..sort(_compareItems);

  final itemsByCategory = <String, List<Item>>{};
  for (final category in categories) {
    itemsByCategory[category.id] = items
        .where((item) => item.categoryId == category.id)
        .toList();
  }

  return ItemListData(
    categories: categories,
    allItems: items,
    itemsByCategory: itemsByCategory,
  );
}

List<Item> applyItemListFilter(List<Item> items, ItemListFilter filter) {
  final today = app_utils.DateUtils.today();

  switch (filter) {
    case ItemListFilter.all:
      return items;
    case ItemListFilter.overdue:
      return items
          .where(
            (item) =>
                item.status == ItemStatus.pending && item.dueDate.isBefore(today),
          )
          .toList();
    case ItemListFilter.history:
      return items
          .where((item) => item.status == ItemStatus.completed)
          .toList();
  }
}

int _compareItems(Item a, Item b) {
  final statusCompare = a.status.index.compareTo(b.status.index);
  if (statusCompare != 0) {
    return statusCompare;
  }

  final dueDateCompare = a.dueDate.compareTo(b.dueDate);
  if (dueDateCompare != 0) {
    return dueDateCompare;
  }

  if (a.dueTime != null && b.dueTime != null) {
    final timeCompare = a.dueTime!.compareTo(b.dueTime!);
    if (timeCompare != 0) {
      return timeCompare;
    }
  } else if (a.dueTime != null) {
    return -1;
  } else if (b.dueTime != null) {
    return 1;
  }

  final priorityCompare = b.priority.index.compareTo(a.priority.index);
  if (priorityCompare != 0) {
    return priorityCompare;
  }

  return a.createdAt.compareTo(b.createdAt);
}
