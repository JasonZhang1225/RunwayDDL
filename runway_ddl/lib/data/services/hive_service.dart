import 'package:hive_flutter/hive_flutter.dart';
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';

class HiveService {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(ItemAdapter());

    await Hive.openBox<Category>('categories');
    await Hive.openBox<Item>('items');
    await Hive.openBox('settings');
  }

  Box<Category> get categoriesBox => Hive.box<Category>('categories');
  Box<Item> get itemsBox => Hive.box<Item>('items');
  Box get settingsBox => Hive.box('settings');

  Future<void> clearAll() async {
    await categoriesBox.clear();
    await itemsBox.clear();
    await settingsBox.clear();
  }
}
