import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';
import 'package:runway_ddl/presentation/providers/items_provider.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;

part 'home_data_provider.g.dart';

class HomePageData {
  final List<Item> overdueItems;
  final List<Item> historyItems;
  final MatrixData mainStreamMatrix;

  HomePageData({
    required this.overdueItems,
    required this.historyItems,
    required this.mainStreamMatrix,
  });

  bool get hasOverdue => overdueItems.isNotEmpty;
  bool get hasHistory => historyItems.isNotEmpty;
  bool get isEmpty => !hasOverdue && !hasHistory && mainStreamMatrix.isEmpty;
}

class MatrixData {
  final List<DateTime> dates;
  final List<Category> categories;
  final Map<String, Map<String, List<Item>>> cells;

  MatrixData({
    required this.dates,
    required this.categories,
    required this.cells,
  });

  List<Item> getItems(DateTime date, Category category) {
    final dateKey = app_utils.DateUtils.formatDate(date);
    return cells[dateKey]?[category.id] ?? [];
  }

  bool get isEmpty {
    for (final dateCells in cells.values) {
      for (final items in dateCells.values) {
        if (items.isNotEmpty) return false;
      }
    }
    return true;
  }
}

@riverpod
HomePageData homeData(HomeDataRef ref) {
  final itemsAsync = ref.watch(itemsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  final items = itemsAsync.valueOrNull ?? [];
  final categories = categoriesAsync.valueOrNull ?? [];
  final today = app_utils.DateUtils.today();

  final overdueItems = items
      .where((item) =>
          item.status == ItemStatus.pending && item.dueDate.isBefore(today))
      .toList()
    ..sort((a, b) => b.overdueDays.compareTo(a.overdueDays));

  final historyItems = items
      .where((item) =>
          item.status == ItemStatus.completed && item.dueDate.isBefore(today))
      .toList()
    ..sort((a, b) {
      if (a.completedAt == null || b.completedAt == null) return 0;
      return b.completedAt!.compareTo(a.completedAt!);
    });

  final dates = List.generate(30, (i) => today.add(Duration(days: i)));
  final cells = _buildCells(items, categories, dates, today);

  return HomePageData(
    overdueItems: overdueItems,
    historyItems: historyItems,
    mainStreamMatrix: MatrixData(
      dates: dates,
      categories: categories,
      cells: cells,
    ),
  );
}

Map<String, Map<String, List<Item>>> _buildCells(
  List<Item> items,
  List<Category> categories,
  List<DateTime> dates,
  DateTime today,
) {
  final cells = <String, Map<String, List<Item>>>{};

  for (final date in dates) {
    final dateKey = app_utils.DateUtils.formatDate(date);
    cells[dateKey] = {};

    for (final category in categories) {
      cells[dateKey]![category.id] = [];
    }
  }

  for (final item in items) {
    if (item.dueDate.isBefore(today)) continue;

    for (final date in dates) {
      if (_shouldShowOnDate(item, date, today)) {
        final dateKey = app_utils.DateUtils.formatDate(date);
        final categoryCell = cells[dateKey]?[item.categoryId];
        if (categoryCell != null) {
          categoryCell.add(item);
        }
        break;
      }
    }
  }

  for (final dateKey in cells.keys) {
    for (final categoryId in cells[dateKey]!.keys) {
      cells[dateKey]![categoryId]!.sort(_compareItems);
    }
  }

  return cells;
}

bool _shouldShowOnDate(Item item, DateTime date, DateTime today) {
  if (item.dueDate.isBefore(today)) return false;
  return app_utils.DateUtils.isSameDay(item.dueDate, date);
}

int _compareItems(Item a, Item b) {
  final statusCompare = a.status.index.compareTo(b.status.index);
  if (statusCompare != 0) return statusCompare;

  final priorityCompare = b.priority.index.compareTo(a.priority.index);
  if (priorityCompare != 0) return priorityCompare;

  if (a.dueTime != null && b.dueTime != null) {
    return a.dueTime!.compareTo(b.dueTime!);
  }

  if (a.dueTime != null) return -1;
  if (b.dueTime != null) return 1;

  return a.createdAt.compareTo(b.createdAt);
}
