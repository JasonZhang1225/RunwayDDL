import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/services/hive_service.dart';

class CategoryException implements Exception {
  final String message;
  CategoryException(this.message);

  @override
  String toString() => 'CategoryException: $message';
}

class CannotDeleteSystemCategoryException extends CategoryException {
  CannotDeleteSystemCategoryException()
      : super('系统内置分类不可删除');
}

class CategoryNameExistsException extends CategoryException {
  CategoryNameExistsException()
      : super('分类名称已存在');
}

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(String id);
  Future<void> create(Category category);
  Future<void> update(Category category);
  Future<void> delete(String id);
  Future<void> initializeDefault();
  Future<bool> nameExists(String name, {String? excludeId});
}

class CategoryRepositoryImpl implements CategoryRepository {
  final HiveService _hiveService;

  CategoryRepositoryImpl(this._hiveService);

  @override
  Future<List<Category>> getAll() async {
    return _hiveService.categoriesBox.values.toList();
  }

  @override
  Future<Category?> getById(String id) async {
    return _hiveService.categoriesBox.get(id);
  }

  @override
  Future<void> create(Category category) async {
    if (await nameExists(category.name)) {
      throw CategoryNameExistsException();
    }

    await _hiveService.categoriesBox.put(category.id, category);
  }

  @override
  Future<void> update(Category category) async {
    final existing = await getById(category.id);
    if (existing == null) return;

    if (await nameExists(category.name, excludeId: category.id)) {
      throw CategoryNameExistsException();
    }

    category.updatedAt = DateTime.now();
    await _hiveService.categoriesBox.put(category.id, category);
  }

  @override
  Future<void> delete(String id) async {
    final category = await getById(id);
    if (category == null) return;

    if (category.isSystem) {
      throw CannotDeleteSystemCategoryException();
    }

    await _hiveService.categoriesBox.delete(id);
  }

  @override
  Future<void> initializeDefault() async {
    const uncategorizedId = 'uncategorized';

    final existing = await getById(uncategorizedId);
    if (existing != null) return;

    final defaultCategory = Category(
      id: uncategorizedId,
      name: '未分类',
      color: '#9E9E9E',
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _hiveService.categoriesBox.put(uncategorizedId, defaultCategory);
  }

  @override
  Future<bool> nameExists(String name, {String? excludeId}) async {
    final categories = await getAll();
    final normalizedName = name.toLowerCase().trim();

    return categories.any((c) =>
        c.name.toLowerCase().trim() == normalizedName &&
        c.id != excludeId);
  }
}
