import 'package:hive/hive.dart';

part 'item.g.dart';

enum ItemPriority { high, medium, low }

enum ItemStatus { pending, completed }

enum DisplayArea { mainStream, overdue, history }

@HiveType(typeId: 1)
class Item extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  final DateTime dueDate;

  @HiveField(5)
  String? dueTime;

  @HiveField(6)
  int _priorityIndex;

  @HiveField(7)
  int _statusIndex;

  @HiveField(8)
  String? imagePath;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  DateTime? completedAt;

  Item({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    required this.dueDate,
    this.dueTime,
    ItemPriority priority = ItemPriority.medium,
    ItemStatus status = ItemStatus.pending,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  })  : _priorityIndex = priority.index,
        _statusIndex = status.index;

  ItemPriority get priority => ItemPriority.values[_priorityIndex];
  set priority(ItemPriority value) => _priorityIndex = value.index;

  ItemStatus get status => ItemStatus.values[_statusIndex];
  set status(ItemStatus value) => _statusIndex = value.index;

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return status == ItemStatus.pending && dueDate.isBefore(today);
  }

  DisplayArea get displayArea {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (dueDate.isBefore(today)) {
      return status == ItemStatus.completed
          ? DisplayArea.history
          : DisplayArea.overdue;
    }
    return DisplayArea.mainStream;
  }

  int get overdueDays {
    if (!isOverdue) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(dueDate).inDays;
  }
}
