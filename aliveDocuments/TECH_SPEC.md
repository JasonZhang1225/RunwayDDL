# RunwayDDL 技术规格说明书

**版本日期**：2026-03-14
**基于文档**：[PRODUCT.md](./PRODUCT.md)、[RULES.md](./RULES.md)、[FREEZE\_DECISIONS.md](./FREEZE_DECISIONS.md)
**适用范围**：Alpha 阶段开发
**文档集**：Alpha Baseline 1

***

## 文档说明

本文档为 RunwayDDL 的技术实现规格，包含：

- 技术栈选型与架构设计
- 数据模型与存储方案
- 核心模块划分与接口定义
- 关键代码模式与最佳实践

***

## A. 技术栈

### A.1 核心框架

| 组件   | 选型         | 版本    | 说明            |
| ---- | ---------- | ----- | ------------- |
| 框架   | Flutter    | 3.16+ | 跨平台 UI 框架     |
| 语言   | Dart       | 3.2+  | 强类型语言         |
| 状态管理 | Riverpod   | 2.4+  | 响应式状态管理       |
| 本地存储 | Hive       | 2.2+  | 轻量级 NoSQL 数据库 |
| 路由   | go\_router | 13.0+ | 声明式路由         |

### A.2 依赖包

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.0
  
  # 路由
  go_router: ^13.0.0
  
  # UI 组件
  flutter_slidable: ^3.0.0
  intl: ^0.18.0
  table_calendar: ^3.0.0
  
  # 图片处理
  image_picker: ^1.0.0
  image: ^4.1.0
  
  # 网络
  dio: ^5.4.0
  
  # 工具
  uuid: ^4.2.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  hive_generator: ^2.0.0
  riverpod_generator: ^2.3.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

### A.3 AI 接入

| 服务       | 用途      | API                    |
| -------- | ------- | ---------------------- |
| 通义千问     | 文本解析    | qwen-turbo / qwen-plus |
| 通义千问 VL  | 图片解析    | qwen-vl-plus           |
| 文心一言（备选） | 文本/图片解析 | ERNIE-Bot / ERNIE-ViLG |

***

## B. 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # App 配置
│
├── core/                        # 核心模块
│   ├── constants/               # 常量定义
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_theme.dart
│   ├── utils/                   # 工具类
│   │   ├── date_utils.dart
│   │   └── validators.dart
│   └── router/                  # 路由配置
│       └── app_router.dart
│
├── data/                        # 数据层
│   ├── models/                  # 数据模型
│   │   ├── category.dart
│   │   ├── item.dart
│   │   └── ai_log.dart
│   ├── repositories/            # 数据仓库
│   │   ├── category_repository.dart
│   │   └── item_repository.dart
│   └── services/                # 服务
│       ├── hive_service.dart
│       └── ai_service.dart
│
├── domain/                      # 领域层
│   ├── entities/                # 实体
│   │   ├── category_entity.dart
│   │   └── item_entity.dart
│   └── usecases/                # 用例
│       ├── create_item.dart
│       ├── update_item.dart
│       └── delete_item.dart
│
├── presentation/                # 展示层
│   ├── providers/               # 状态提供者
│   │   ├── categories_provider.dart
│   │   ├── items_provider.dart
│   │   └── home_data_provider.dart
│   ├── pages/                   # 页面
│   │   ├── home/
│   │   │   ├── home_page.dart
│   │   │   ├── home_viewmodel.dart
│   │   │   └── widgets/
│   │   │       ├── overdue_section.dart
│   │   │       ├── history_section.dart
│   │   │       ├── date_stream_matrix.dart
│   │   │       └── task_card.dart
│   │   ├── add_item/
│   │   │   ├── add_item_sheet.dart
│   │   │   └── widgets/
│   │   │       ├── manual_form.dart
│   │   │       ├── quick_input.dart
│   │   │       └── image_input.dart
│   │   ├── category/
│   │   │   ├── category_page.dart
│   │   │   └── widgets/
│   │   │       └── category_item.dart
│   │   ├── item_detail/
│   │   │   └── item_detail_page.dart
│   │   └── settings/
│   │       └── settings_page.dart
│   └── widgets/                 # 通用组件
│       ├── app_button.dart
│       ├── app_text_field.dart
│       └── confirm_dialog.dart
│
└── generated/                   # 生成代码
    └── ...
```

***

## C. 数据模型

### C.1 Category 模型

```dart
@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String color;
  
  @HiveField(3)
  int sortOrder;
  
  @HiveField(4)
  final bool isSystem;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  DateTime updatedAt;
  
  Category({
    required this.id,
    required this.name,
    required this.color,
    this.sortOrder = 0,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  bool get canEdit => !isSystem;
  bool get canDelete => !isSystem;
}
```

### C.2 Item 模型

```dart
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
  TimeOfDay? dueTime;
  
  @HiveField(6)
  ItemPriority priority;
  
  @HiveField(7)
  ItemStatus status;
  
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
    this.priority = ItemPriority.medium,
    this.status = ItemStatus.pending,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  
  bool get isOverdue {
    return status == ItemStatus.pending && 
           dueDate.isBefore(DateUtils.dateOnly(DateTime.now()));
  }
  
  DisplayArea get displayArea {
    final today = DateUtils.dateOnly(DateTime.now());
    if (dueDate.isBefore(today)) {
      return status == ItemStatus.completed 
          ? DisplayArea.history 
          : DisplayArea.overdue;
    }
    return DisplayArea.mainStream;
  }
  
  int get overdueDays {
    if (!isOverdue) return 0;
    final today = DateUtils.dateOnly(DateTime.now());
    return today.difference(dueDate).inDays;
  }
}

enum ItemPriority { high, medium, low }

enum ItemStatus { pending, completed }

enum DisplayArea { mainStream, overdue, history }
```

### C.3 首页数据结构

```dart
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
    final dateKey = DateUtils.formatDate(date);
    return cells[dateKey]?[category.id] ?? [];
  }
  
  bool get isEmpty => cells.isEmpty;
}
```

***

## D. 核心模块设计

### D.0 首页双层结构

#### 数据流设计

```
┌─────────────────────────────────────────────────────────────┐
│                      HomePageData                            │
├─────────────────────────────────────────────────────────────┤
│  overdueItems: List<Item>     ← 未完成 && dueDate < today   │
│  historyItems: List<Item>     ← 已完成 && dueDate < today   │
│  mainStreamMatrix: MatrixData ← dueDate >= today (30天)     │
└─────────────────────────────────────────────────────────────┘
```

#### Provider 设计

```dart
@riverpod
HomePageData homeData(HomeDataRef ref) {
  final items = ref.watch(itemsProvider);
  final categories = ref.watch(categoriesProvider);
  final today = DateUtils.dateOnly(DateTime.now());
  
  final overdueItems = items
      .where((item) => item.status == ItemStatus.pending && 
                       item.dueDate.isBefore(today))
      .toList()
    ..sort((a, b) => b.overdueDays.compareTo(a.overdueDays));
  
  final historyItems = items
      .where((item) => item.status == ItemStatus.completed && 
                       item.dueDate.isBefore(today))
      .toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  
  final dates = List.generate(30, (i) => today.add(Duration(days: i)));
  final cells = <String, Map<String, List<Item>>>{};
  
  for (final date in dates) {
    final dateKey = DateUtils.formatDate(date);
    cells[dateKey] = {};
    
    for (final category in categories) {
      final categoryItems = items
          .where((item) => 
              item.categoryId == category.id &&
              _shouldShowOnDate(item, date, today))
          .toList()
        ..sort(_compareItems);
      
      if (categoryItems.isNotEmpty) {
        cells[dateKey]![category.id] = categoryItems;
      }
    }
  }
  
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

bool _shouldShowOnDate(Item item, DateTime date, DateTime today) {
  if (item.dueDate.isBefore(today)) return false;
  
  final daysUntilDue = item.dueDate.difference(date).inDays;
  return daysUntilDue >= 0 && daysUntilDue <= 3;
}

int _compareItems(Item a, Item b) {
  final statusCompare = a.status.index.compareTo(b.status.index);
  if (statusCompare != 0) return statusCompare;
  
  final priorityCompare = b.priority.index.compareTo(a.priority.index);
  if (priorityCompare != 0) return priorityCompare;
  
  if (a.dueTime != null && b.dueTime != null) {
    return a.dueTime!.compareTo(b.dueTime!);
  }
  
  return a.createdAt.compareTo(b.createdAt);
}
```

#### 组件结构

```dart
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeDataProvider);
    
    return Scaffold(
      appBar: _buildAppBar(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildFixedSections(homeData),
          ),
          SliverToBoxAdapter(
            child: _buildMatrix(homeData.mainStreamMatrix),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }
  
  Widget _buildFixedSections(HomePageData homeData) {
    return Column(
      children: [
        if (homeData.hasOverdue) 
          OverdueSection(items: homeData.overdueItems),
        if (homeData.hasHistory) 
          HistorySection(items: homeData.historyItems),
      ],
    );
  }
}
```

### D.1 分类管理模块

#### Repository 接口

```dart
abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(String id);
  Future<void> create(Category category);
  Future<void> update(Category category);
  Future<void> delete(String id);
  Future<void> initializeDefault();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final HiveService _hiveService;
  
  @override
  Future<void> initializeDefault() async {
    final existing = await getAll();
    if (existing.any((c) => c.id == 'uncategorized')) return;
    
    await create(Category(
      id: 'uncategorized',
      name: '未分类',
      color: '#9E9E9E',
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }
  
  @override
  Future<void> delete(String id) async {
    final category = await getById(id);
    if (category == null) return;
    
    if (category.isSystem) {
      throw CannotDeleteSystemCategoryException();
    }
    
    final itemRepo = ItemRepositoryImpl(_hiveService);
    await itemRepo.migrateToUncategorized(id);
    
    await _hiveService.deleteCategory(id);
  }
}
```

#### Provider

```dart
@riverpod
class Categories extends _$Categories {
  @override
  Future<List<Category>> build() async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.initializeDefault();
    return repo.getAll();
  }
  
  Future<void> create(String name, String color) async {
    final repo = ref.read(categoryRepositoryProvider);
    final existing = state.value ?? [];
    
    if (existing.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      throw CategoryNameExistsException();
    }
    
    await repo.create(Category(
      id: Uuid().v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    
    ref.invalidateSelf();
  }
  
  Future<void> delete(String id) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}
```

### D.2 事项管理模块

#### Repository 接口

```dart
abstract class ItemRepository {
  Future<List<Item>> getAll();
  Future<Item?> getById(String id);
  Future<void> create(Item item);
  Future<void> update(Item item);
  Future<void> delete(String id);
  Future<void> migrateToUncategorized(String oldCategoryId);
  Future<void> markCompleted(String id);
  Future<void> markPending(String id);
}

class ItemRepositoryImpl implements ItemRepository {
  final HiveService _hiveService;
  
  @override
  Future<void> migrateToUncategorized(String oldCategoryId) async {
    final items = await getAll();
    final toMigrate = items.where((i) => i.categoryId == oldCategoryId);
    
    for (final item in toMigrate) {
      item.categoryId = 'uncategorized';
      item.updatedAt = DateTime.now();
      await _hiveService.updateItem(item);
    }
  }
  
  @override
  Future<void> markCompleted(String id) async {
    final item = await getById(id);
    if (item == null) return;
    
    item.status = ItemStatus.completed;
    item.completedAt = DateTime.now();
    item.updatedAt = DateTime.now();
    await _hiveService.updateItem(item);
  }
}
```

#### Provider

```dart
@riverpod
class Items extends _$Items {
  @override
  Future<List<Item>> build() async {
    final repo = ref.read(itemRepositoryProvider);
    return repo.getAll();
  }
  
  Future<void> create({
    required String title,
    required DateTime dueDate,
    String categoryId = 'uncategorized',
    TimeOfDay? dueTime,
    ItemPriority priority = ItemPriority.medium,
    String? description,
    String? imagePath,
  }) async {
    final repo = ref.read(itemRepositoryProvider);
    
    await repo.create(Item(
      id: Uuid().v4(),
      title: title,
      description: description,
      categoryId: categoryId,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    
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
```

### D.3 AI 解析模块

#### 服务接口

```dart
abstract class AIService {
  Future<ParseResult> parseText(String input);
  Future<ParseResult> parseImage(String imagePath);
}

class AIServiceImpl implements AIService {
  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;
  
  @override
  Future<ParseResult> parseText(String input) async {
    final prompt = '''
请从以下自然语言描述中提取任务信息，返回 JSON 格式：

输入：$input

返回格式：
{
  "title": "任务标题",
  "date": "YYYY-MM-DD 或相对日期描述",
  "time": "HH:MM 或 null",
  "category_hint": "分类关键词",
  "priority": "high/medium/low"
}
''';
    
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        headers: {'Authorization': 'Bearer $_apiKey'},
        data: {
          'model': 'qwen-plus',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        },
      );
      
      final content = response.data['choices'][0]['message']['content'];
      return _parseResponse(content);
    } catch (e) {
      return ParseResult.failed();
    }
  }
  
  @override
  Future<ParseResult> parseImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final prompt = '''
请分析这张图片，提取其中的任务信息：

1. 如果是课程表：提取课程名称、时间、地点
2. 如果是会议白板：提取会议主题、时间、待办事项
3. 如果是手写便签：提取文字内容中的任务信息
4. 如果是截图：提取其中的截止日期、任务描述

返回 JSON 格式：
{
  "title": "任务标题",
  "date": "YYYY-MM-DD",
  "time": "HH:MM 或 null",
  "category_hint": "分类关键词",
  "priority": "high/medium/low",
  "ocr_text": "图片中识别的原始文字"
}
''';
    
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        headers: {'Authorization': 'Bearer $_apiKey'},
        data: {
          'model': 'qwen-vl-plus',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ]
            }
          ],
        },
      );
      
      final content = response.data['choices'][0]['message']['content'];
      return _parseResponse(content);
    } catch (e) {
      return ParseResult.failed();
    }
  }
  
  ParseResult _parseResponse(String content) {
    try {
      final json = jsonDecode(content);
      return ParseResult(
        title: json['title'],
        date: _parseDate(json['date']),
        time: _parseTime(json['time']),
        categoryHint: json['category_hint'],
        priority: _parsePriority(json['priority']),
        confidence: _calculateConfidence(json),
      );
    } catch (e) {
      return ParseResult.failed();
    }
  }
}

class ParseResult {
  final String? title;
  final DateTime? date;
  final TimeOfDay? time;
  final String? categoryHint;
  final ItemPriority priority;
  final double confidence;
  final bool success;
  
  ParseResult({
    this.title,
    this.date,
    this.time,
    this.categoryHint,
    this.priority = ItemPriority.medium,
    this.confidence = 0.0,
    this.success = true,
  });
  
  factory ParseResult.failed() => ParseResult(success: false);
}
```

### D.4 图片输入模块

#### 图片选择服务

```dart
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  
  Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return image?.path;
  }
  
  Future<String?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return image?.path;
  }
  
  Future<String> saveToAppStorage(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = '${appDir.path}/images/$fileName';
    
    await Directory('${appDir.path}/images').create(recursive: true);
    await File(sourcePath).copy(destPath);
    
    return destPath;
  }
}
```

#### 图片输入组件

```dart
class ImageInputWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImage = ref.watch(selectedImageProvider);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text('选择图片'),
              onPressed: () => _pickFromGallery(context, ref),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('拍照'),
              onPressed: () => _pickFromCamera(context, ref),
            ),
          ],
        ),
        if (selectedImage != null) ...[
          SizedBox(height: 16),
          _buildImagePreview(selectedImage),
        ],
      ],
    );
  }
  
  Widget _buildImagePreview(String path) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => ref.read(selectedImageProvider.notifier).clear(),
          ),
        ),
      ],
    );
  }
}
```

### D.5 XY 轴互换模块（Alpha 后段）

#### 视图模式管理

```dart
enum ViewMode { dateVertical, categoryVertical }

@riverpod
class ViewModeNotifier extends _$ViewModeNotifier {
  @override
  ViewMode build() => ViewMode.dateVertical;
  
  void toggle() {
    state = state == ViewMode.dateVertical 
        ? ViewMode.categoryVertical 
        : ViewMode.dateVertical;
  }
}
```

#### 矩阵渲染适配

```dart
class MatrixWidget extends ConsumerWidget {
  final MatrixData data;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeNotifierProvider);
    
    return viewMode == ViewMode.dateVertical
        ? _buildDateVerticalMatrix()
        : _buildCategoryVerticalMatrix();
  }
  
  Widget _buildDateVerticalMatrix() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          children: [
            _buildHeaderRow(),
            ...data.dates.map((date) => _buildDateRow(date)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryVerticalMatrix() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          children: [
            _buildHeaderRowSwapped(),
            ...data.categories.map((cat) => _buildCategoryRow(cat)),
          ],
        ),
      ),
    );
  }
}
```

***

## E. 存储方案

### E.1 Hive 初始化

```dart
class HiveService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(ItemAdapter());
    Hive.registerAdapter(ItemPriorityAdapter());
    Hive.registerAdapter(ItemStatusAdapter());
    
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
```

### E.2 数据迁移策略

```dart
class DataMigration {
  static Future<void> migrateToV021() async {
    final categoriesBox = Hive.box<Category>('categories');
    
    if (!categoriesBox.containsKey('uncategorized')) {
      await categoriesBox.put('uncategorized', Category(
        id: 'uncategorized',
        name: '未分类',
        color: '#9E9E9E',
        isSystem: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    
    final itemsBox = Hive.box<Item>('items');
    final itemsWithoutCategory = itemsBox.values
        .where((item) => item.categoryId.isEmpty);
    
    for (final item in itemsWithoutCategory) {
      item.categoryId = 'uncategorized';
      await item.save();
    }
  }
}
```

***

## F. 关键代码模式

### F.1 overdue 计算模式

**错误做法（不要这样）**：

```dart
@HiveField(8)
bool isOverdue;  // ❌ 不要存储逾期状态
```

**正确做法**：

```dart
bool get isOverdue {  // ✓ 计算属性
  return status == ItemStatus.pending && 
         dueDate.isBefore(DateUtils.today);
}
```

### F.2 区域判定模式

```dart
DisplayArea get displayArea {
  final today = DateUtils.dateOnly(DateTime.now());
  
  if (dueDate.isBefore(today)) {
    return status == ItemStatus.completed 
        ? DisplayArea.history 
        : DisplayArea.overdue;
  }
  
  return DisplayArea.mainStream;
}
```

### F.3 分类删除迁移模式

```dart
Future<void> deleteCategory(String categoryId) async {
  final category = await getCategory(categoryId);
  
  if (category?.isSystem == true) {
    throw CannotDeleteSystemCategoryException();
  }
  
  final items = await getItemsByCategory(categoryId);
  
  for (final item in items) {
    item.categoryId = 'uncategorized';
    item.updatedAt = DateTime.now();
    await updateItem(item);
  }
  
  await deleteCategoryRecord(categoryId);
}
```

### F.4 首页数据分组模式

```dart
HomePageData groupItemsForHome(List<Item> items, List<Category> categories) {
  final today = DateUtils.dateOnly(DateTime.now());
  
  final overdueItems = items
      .where((i) => i.status == ItemStatus.pending && i.dueDate.isBefore(today))
      .toList()
    ..sort((a, b) => b.overdueDays.compareTo(a.overdueDays));
  
  final historyItems = items
      .where((i) => i.status == ItemStatus.completed && i.dueDate.isBefore(today))
      .toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  
  final matrix = _buildMatrix(items, categories, today);
  
  return HomePageData(
    overdueItems: overdueItems,
    historyItems: historyItems,
    mainStreamMatrix: matrix,
  );
}
```

***

## G. 性能优化

### G.1 列表虚拟化

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return TaskCard(item: items[index]);
  },
)
```

### G.2 图片压缩

```dart
Future<File> compressImage(File image) async {
  final tempDir = await getTemporaryDirectory();
  final targetPath = '${tempDir.path}/compressed.jpg';
  
  final compressed = await FlutterImageCompress.compressAndGetFile(
    image.absolute.path,
    targetPath,
    quality: 85,
    minWidth: 1920,
    minHeight: 1080,
  );
  
  return File(compressed!.path);
}
```

### G.3 状态缓存

```dart
@riverpod
class Items extends _$Items {
  @override
  Future<List<Item>> build() async {
    ref.cacheFor(Duration(minutes: 5));
    return _fetchAllItems();
  }
}
```

***

## H. 测试策略

### H.1 单元测试

```dart
void main() {
  group('Item', () {
    test('isOverdue returns true for pending items with past due date', () {
      final item = Item(
        id: '1',
        title: 'Test',
        categoryId: 'uncategorized',
        dueDate: DateTime.now().subtract(Duration(days: 1)),
        status: ItemStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      expect(item.isOverdue, isTrue);
    });
    
    test('isOverdue returns false for completed items', () {
      final item = Item(
        id: '1',
        title: 'Test',
        categoryId: 'uncategorized',
        dueDate: DateTime.now().subtract(Duration(days: 1)),
        status: ItemStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      expect(item.isOverdue, isFalse);
    });
    
    test('displayArea returns overdue for pending past items', () {
      final item = Item(
        id: '1',
        title: 'Test',
        categoryId: 'uncategorized',
        dueDate: DateTime.now().subtract(Duration(days: 1)),
        status: ItemStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      expect(item.displayArea, equals(DisplayArea.overdue));
    });
    
    test('displayArea returns history for completed past items', () {
      final item = Item(
        id: '1',
        title: 'Test',
        categoryId: 'uncategorized',
        dueDate: DateTime.now().subtract(Duration(days: 1)),
        status: ItemStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      expect(item.displayArea, equals(DisplayArea.history));
    });
  });
}
```

### H.2 Widget 测试

```dart
void main() {
  testWidgets('OverdueSection displays overdue items', (tester) async {
    final items = [
      Item(
        id: '1',
        title: 'Overdue Task',
        categoryId: 'uncategorized',
        dueDate: DateTime.now().subtract(Duration(days: 2)),
        status: ItemStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OverdueSection(items: items),
      ),
    ));
    
    expect(find.text('逾期事项 (1)'), findsOneWidget);
    expect(find.text('Overdue Task'), findsOneWidget);
    expect(find.text('逾期2天'), findsOneWidget);
  });
}
```

***

## I. 部署配置

### I.1 环境变量

```env
AI_API_KEY=your_api_key_here
AI_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
```

### I.2 Android 配置

```xml
<manifest>
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
</manifest>
```

### I.3 iOS 配置

```xml
<key>NSCameraUsageDescription</key>
<string>需要相机权限来拍摄任务相关图片</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要相册权限来选择任务相关图片</string>
```

***

## J. 技术债务追踪

| 债务项         | 影响      | 计划解决版本 |
| ----------- | ------- | ------ |
| 本地存储无云端同步   | 换设备数据丢失 | v1.0   |
| AI 准确率依赖第三方 | 解析结果不稳定 | 持续优化   |
| 大量分类时性能下降   | 滚动卡顿    | Beta   |
| 图片未加密存储     | 隐私风险    | v1.0   |

***

**文档结束**

**版本记录**：

- 历史版本归档于 `archieve/history/` 目录
- 当前版本基于冻结裁决整合，详见 [FREEZE\_DECISIONS.md](./FREEZE_DECISIONS.md)

