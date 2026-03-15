import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/repositories/item_repository.dart';
import 'package:runway_ddl/presentation/providers/categories_provider.dart';
import 'package:runway_ddl/presentation/providers/image_picker_provider.dart';

part 'items_provider.g.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepositoryImpl(ref.watch(hiveServiceProvider));
});

@riverpod
class Items extends _$Items {
  @override
  Future<List<Item>> build() async {
    final repo = ref.read(itemRepositoryProvider);
    return repo.getAll();
  }

  Future<void> createItem({
    required String title,
    required DateTime dueDate,
    String categoryId = 'uncategorized',
    String? dueTime,
    ItemPriority priority = ItemPriority.medium,
    String? description,
    String? imagePath,
  }) async {
    final repo = ref.read(itemRepositoryProvider);

    final item = Item(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description?.trim(),
      categoryId: categoryId,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.create(item);
    ref.invalidateSelf();
  }

  Future<void> updateItem(Item item, {String? oldImagePath}) async {
    final repo = ref.read(itemRepositoryProvider);
    if (oldImagePath != null && oldImagePath != item.imagePath) {
      final imageService = ref.read(imagePickerProvider);
      await imageService.deleteImage(oldImagePath);
    }
    await repo.update(item);
    ref.invalidateSelf();
  }

  Future<void> deleteItem(String id) async {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.getById(id);
    if (item?.imagePath != null) {
      final imageService = ref.read(imagePickerProvider);
      await imageService.deleteImage(item!.imagePath!);
    }
    await repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> toggleStatus(String id) async {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.getById(id);

    if (item == null) return;

    if (item.status == ItemStatus.pending) {
      await repo.markCompleted(id);
    } else {
      await repo.markPending(id);
    }

    ref.invalidateSelf();
  }
}

@riverpod
Item? itemById(ItemByIdRef ref, String id) {
  final items = ref.watch(itemsProvider).valueOrNull;
  if (items == null) return null;
  try {
    return items.firstWhere((i) => i.id == id);
  } catch (_) {
    return null;
  }
}

@riverpod
List<Item> itemsByCategory(ItemsByCategoryRef ref, String categoryId) {
  final items = ref.watch(itemsProvider).valueOrNull ?? [];
  return items.where((i) => i.categoryId == categoryId).toList();
}

@riverpod
List<Item> overdueItems(OverdueItemsRef ref) {
  final items = ref.watch(itemsProvider).valueOrNull ?? [];
  return items.where((i) => i.isOverdue).toList()
    ..sort((a, b) => b.overdueDays.compareTo(a.overdueDays));
}

@riverpod
List<Item> historyItems(HistoryItemsRef ref) {
  final items = ref.watch(itemsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return items
      .where((i) =>
          i.status == ItemStatus.completed && i.dueDate.isBefore(today))
      .toList()
    ..sort((a, b) {
      if (a.completedAt == null || b.completedAt == null) return 0;
      return b.completedAt!.compareTo(a.completedAt!);
    });
}
