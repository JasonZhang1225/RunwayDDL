import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/services/hive_service.dart';

class ItemException implements Exception {
  final String message;
  ItemException(this.message);

  @override
  String toString() => 'ItemException: $message';
}

abstract class ItemRepository {
  Future<List<Item>> getAll();
  Future<Item?> getById(String id);
  Future<void> create(Item item);
  Future<void> update(Item item);
  Future<void> delete(String id);
  Future<void> migrateToUncategorized(String oldCategoryId);
  Future<void> markCompleted(String id);
  Future<void> markPending(String id);
  Future<List<Item>> getByCategoryId(String categoryId);
}

class ItemRepositoryImpl implements ItemRepository {
  final HiveService _hiveService;

  ItemRepositoryImpl(this._hiveService);

  @override
  Future<List<Item>> getAll() async {
    return _hiveService.itemsBox.values.toList();
  }

  @override
  Future<Item?> getById(String id) async {
    return _hiveService.itemsBox.get(id);
  }

  @override
  Future<void> create(Item item) async {
    await _hiveService.itemsBox.put(item.id, item);
  }

  @override
  Future<void> update(Item item) async {
    final existing = await getById(item.id);
    if (existing == null) return;

    item.updatedAt = DateTime.now();
    await _hiveService.itemsBox.put(item.id, item);
  }

  @override
  Future<void> delete(String id) async {
    await _hiveService.itemsBox.delete(id);
  }

  @override
  Future<void> migrateToUncategorized(String oldCategoryId) async {
    final items = await getByCategoryId(oldCategoryId);

    for (final item in items) {
      item.categoryId = 'uncategorized';
      item.updatedAt = DateTime.now();
      await _hiveService.itemsBox.put(item.id, item);
    }
  }

  @override
  Future<void> markCompleted(String id) async {
    final item = await getById(id);
    if (item == null) return;

    item.status = ItemStatus.completed;
    item.completedAt = DateTime.now();
    item.updatedAt = DateTime.now();
    await _hiveService.itemsBox.put(id, item);
  }

  @override
  Future<void> markPending(String id) async {
    final item = await getById(id);
    if (item == null) return;

    item.status = ItemStatus.pending;
    item.completedAt = null;
    item.updatedAt = DateTime.now();
    await _hiveService.itemsBox.put(id, item);
  }

  @override
  Future<List<Item>> getByCategoryId(String categoryId) async {
    final items = await getAll();
    return items.where((item) => item.categoryId == categoryId).toList();
  }
}
