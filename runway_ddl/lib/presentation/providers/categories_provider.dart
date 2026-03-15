import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/repositories/category_repository.dart';
import 'package:runway_ddl/data/services/hive_service.dart';

part 'categories_provider.g.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(hiveServiceProvider));
});

@riverpod
class Categories extends _$Categories {
  @override
  Future<List<Category>> build() async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.initializeDefault();
    return repo.getAll();
  }

  Future<void> createCategory(String name, String color) async {
    final repo = ref.read(categoryRepositoryProvider);

    final category = Category(
      id: const Uuid().v4(),
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.create(category);
    ref.invalidateSelf();
  }

  Future<void> updateCategory(String id, {String? name, String? color}) async {
    final repo = ref.read(categoryRepositoryProvider);
    final category = await repo.getById(id);

    if (category == null) return;

    if (name != null) category.name = name.trim();
    if (color != null) category.color = color;

    await repo.update(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(String id) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

@riverpod
Category? categoryById(CategoryByIdRef ref, String id) {
  final categories = ref.watch(categoriesProvider).valueOrNull;
  if (categories == null) return null;
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
