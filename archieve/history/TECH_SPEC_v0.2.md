# RunwayDDL 技术方案 v0.2

**版本日期**：2026-03-14  
**基于文档**：
- [PRODUCT_v0.2.md](./PRODUCT_v0.2.md)
- [PROTOTYPE_v0.2.md](./PROTOTYPE_v0.2.md)
- [TASK_BREAKDOWN_v0.2.md](./TASK_BREAKDOWN_v0.2.md)

---

## A. 技术决策总览

### A.1 Flutter 架构分层

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # MaterialApp 配置
├── models/                      # 数据模型层
│   ├── category.dart
│   ├── item.dart
│   └── ai_log.dart
├── services/                    # 服务层（纯逻辑，无 UI 状态）
│   ├── storage_service.dart     # Hive 存储封装
│   ├── image_storage_service.dart  # 图片文件管理
│   └── ai_service.dart          # AI API 封装
├── providers/                   # 状态管理层（Riverpod）
│   ├── category_provider.dart   # 分类状态
│   ├── item_provider.dart       # 任务状态（核心）
│   └── quick_add_provider.dart  # 快捷添加流程状态
├── pages/                       # 页面层
│   ├── home_page.dart
│   ├── category_management_page.dart
│   ├── item_detail_page.dart
│   └── settings_page.dart
├── widgets/                     # 可复用组件
│   ├── date_stream_matrix.dart  # 首页核心矩阵
│   ├── task_card.dart
│   ├── add_item_dialog.dart
│   └── ...
└── utils/                       # 工具函数
    ├── date_utils.dart
    └── constants.dart
```

**分层职责**：

| 层级 | 职责 | 禁止做的事 |
|------|------|-----------|
| models | 定义数据结构，序列化/反序列化 | 不包含业务逻辑 |
| services | 封装外部依赖（存储、网络、文件系统） | 不持有 UI 状态，不调用 setState |
| providers | 管理应用状态，业务逻辑编排 | 不直接操作 Hive/HTTP，通过 services |
| pages | 页面布局，响应式构建 | 不包含业务逻辑，只调用 provider 方法 |
| widgets | 纯展示组件，接收参数回调 | 不直接依赖 services |

### A.2 状态管理：为何选 Riverpod

**决策理由**：

1. **编译时安全**：Provider 的查找在编译期验证，避免运行时找不到 Provider 的崩溃
2. **代码生成友好**：配合 `@riverpod` 注解，AI 生成代码更规范
3. **自动依赖追踪**：当 Category 变化时，依赖它的 ItemProvider 自动重建
4. **测试友好**：Provider 容器可覆盖，方便单元测试

**替代方案对比**：

| 方案 | 不选原因 |
|------|----------|
| Provider (原始) | 缺乏编译时检查，容易写出隐式依赖 |
| Bloc | 样板代码多，MVP 阶段过度设计 |
| GetX | 全局状态管理过于魔法，不利于代码审查 |
| MobX | 需要代码生成，增加构建复杂度 |

**MVP 必用**：Riverpod + flutter_riverpod  
**可延后**：代码生成（riverpod_generator）先用基础版，后期迁移成本低

### A.3 本地存储：为何选 Hive

**决策理由**：

1. **性能**：Hive 是纯 Dart 实现，无平台通道开销，读写速度比 SQLite 快 2-5 倍
2. **类型安全**：支持自定义对象直接存储，无需手动 SQL 拼接
3. **无模式迁移**：MVP 阶段数据结构变化频繁，Hive 无需写 migration
4. **体积小**：Release 包增加 < 500KB

**字段对比**：

| 特性 | Hive | SQLite/Drift |
|------|------|--------------|
| 查询能力 | 弱（全表扫描） | 强（索引、复杂查询） |
| 数据量 | < 10MB 表现优秀 | > 100MB 仍稳定 |
| 类型安全 | 需手动 adapter | Drift 自动生成 |
| 迁移成本 | 低 | 中（需写 migration） |
| 包体积 | 小 | 中（Drift 依赖较多） |

**MVP 决策**：
- **必用**：Hive（任务量预期 < 1000 条，完全够用）
- **备选**：Drift（如果后期需要复杂查询，迁移成本可控）
- **不选**：纯 SQLite（样板代码多，MVP 不值得）

### A.4 图片存储策略

**存储位置**：应用沙盒目录（`getApplicationDocumentsDirectory()`）

```
/app_documents/
  └── images/
      ├── img_20260314_103022_a1b2c3d4.jpg
      ├── img_20260314_112345_e5f6g7h8.png
      └── ...
```

**命名规则**：`img_{timestamp}_{uuid前8位}.{ext}`

**存储策略**：

| 场景 | 处理方式 |
|------|----------|
| 用户选择图片 | 复制到沙盒，原路径保存到 `image_path` |
| 用户拍照 | 直接保存到沙盒 |
| 图片删除 | 物理删除文件 + 清空 `image_path` |
| 应用卸载 | 数据随应用一起删除（符合用户预期） |

**限制**：
- MVP 单张图片限制 10MB
- 格式限制：JPG、PNG、HEIC
- 不压缩原图（后期可优化）

### A.5 AI 服务接入方式

**架构选择**：前端直连（MVP 阶段可接受）

```
┌─────────────┐     HTTPS      ┌─────────────────┐
│   Flutter   │ ─────────────→ │   国产 LLM API   │
│   App       │                │  (通义千问 VL)   │
└─────────────┘                └─────────────────┘
```

**理由**：
1. MVP 阶段用户量小，API Key 泄露风险可控
2. 减少后端部署成本，加速上线
3. 通义千问 VL 支持 CORS，前端可直接调用

**安全兜底**：
- API Key 存储在环境变量，不提交到 Git
- 提供 Key 轮换机制（一个 Key 被封可快速切换）
- 请求添加签名验证（时间戳 + Key 哈希）

**备选方案（v0.3 考虑）**：
```
Flutter → 自建代理服务器 → LLM API
```

### A.6 为何这些选择适合 MVP

| 维度 | 选择 | 适合 MVP 的原因 |
|------|------|----------------|
| 开发速度 | Riverpod + Hive | 样板代码少，热重载友好 |
| 调试成本 | 前端直连 AI | 减少一层网络跳转，问题定位快 |
| 包体积 | Hive + Riverpod | Release 包预计 < 30MB |
| 学习成本 | 全 Dart 栈 | 团队无需学习 SQL/Swift/Kotlin |
| 扩展性 | 分层架构 | 后期迁移到云端只需改 services 层 |

---

## B. 模块设计

### B.1 models 层

**Category 模型**：

```dart
@immutable
class Category {
  final String id;           // UUID v4
  final String name;         // 最多 10 字符
  final String color;        // Hex 格式，如 #1976D2
  final int sortOrder;       // 排序权重
  final DateTime createdAt;
  final DateTime updatedAt;

  // 序列化方法
  factory Category.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  // 不可变更新
  Category copyWith({...});
}
```

**Item 模型**：

```dart
@immutable
class Item {
  final String id;
  final String title;        // 最多 100 字符
  final String? description;
  final String categoryId;   // 外键
  final DateTime dueDate;    // 截止日期
  final TimeOfDay? dueTime;  // 截止时间（可选）
  final Priority priority;   // high/medium/low
  final ItemStatus status;   // pending/completed
  final String? imagePath;   // 图片本地路径（可选）
  final DateTime createdAt;
  final DateTime updatedAt;

  // 计算属性（不在 Hive 中存储）
  bool get isOverdue => status == pending && dueDate.isBefore(today);
  bool get shouldDisplay(DateTime date) => 
    date.isBetween(dueDate.subtract(3.days), dueDate);
}
```

**职责边界**：
- 只定义数据结构和基础计算属性
- 不包含存储逻辑、UI 逻辑
- 所有字段不可变（final），更新通过 copyWith

### B.2 services 层

**StorageService**：

```dart
class StorageService {
  // 单例模式
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  late Box<Category> _categoryBox;
  late Box<Item> _itemBox;

  // 初始化
  Future<void> initialize();

  // Category CRUD
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategory(String id);
  Future<void> saveCategory(Category category);
  Future<void> deleteCategory(String id);

  // Item CRUD
  Future<List<Item>> getAllItems();
  Future<List<Item>> getItemsByDate(DateTime date);
  Future<List<Item>> getItemsByCategory(String categoryId);
  Future<void> saveItem(Item item);
  Future<void> deleteItem(String id);

  // 批量操作
  Future<void> clearAllData();
}
```

**ImageStorageService**：

```dart
class ImageStorageService {
  // 保存图片，返回存储路径
  Future<String> saveImage(File sourceFile);
  
  // 删除图片
  Future<void> deleteImage(String path);
  
  // 获取图片文件
  File? getImageFile(String path);
  
  // 清理未引用的图片（垃圾回收）
  Future<void> cleanupOrphanedImages(List<String> referencedPaths);
}
```

**AIService**：

```dart
class AIService {
  // 文本解析
  Future<AIParseResult> parseText(String input);
  
  // 图片解析（多模态）
  Future<AIParseResult> parseImage(File imageFile);
  
  // 统一结果结构
  // { title, date, time, categoryHint, priority, ocrText?, confidence }
}
```

**职责边界**：
- 封装所有外部依赖（Hive、文件系统、HTTP）
- 方法签名使用领域对象（Category/Item），不暴露 Hive Box
- 处理所有异常，转换为自定义异常类型
- 不持有任何 UI 状态

### B.3 providers 层

**CategoryProvider**：

```dart
@riverpod
class CategoryNotifier extends _$CategoryNotifier {
  late StorageService _storage;

  @override
  Future<List<Category>> build() async {
    _storage = ref.watch(storageServiceProvider);
    return _storage.getAllCategories();
  }

  Future<void> addCategory(String name, String color);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<void> reorderCategories(List<Category> newOrder);
}
```

**ItemProvider（核心）**：

```dart
@riverpod
class ItemNotifier extends _$ItemNotifier {
  // 核心职责：
  // 1. 管理任务列表状态
  // 2. 实现跨天展示逻辑（截止前3天）
  // 3. 实现筛选逻辑（时间范围、分类、状态）
  // 4. 实现排序逻辑（优先级、截止时间）

  @override
  Future<List<Item>> build() async { ... }

  // 获取某日期某分类的任务（首页矩阵用）
  List<Item> getItemsForCell(DateTime date, String categoryId);
  
  // 获取某日期所有任务（跨天展开后）
  List<Item> getItemsForDate(DateTime date);
  
  // CRUD
  Future<void> addItem(Item item);
  Future<void> updateItem(Item item);
  Future<void> deleteItem(String id);
  Future<void> toggleComplete(String id);
}
```

**QuickAddProvider**：

```dart
@riverpod
class QuickAddNotifier extends _$QuickAddNotifier {
  // 管理快捷添加流程状态
  // 输入方式（文本/图片）
  // 解析状态（idle/loading/success/error）
  // 解析结果预览
  // 用户确认后的创建逻辑
}
```

**职责边界**：
- 持有 UI 相关的状态（加载中、错误信息）
- 编排 services 完成业务逻辑
- 处理用户操作（点击、输入）
- 通过 ref.watch 实现自动依赖更新

### B.4 pages 层

**页面职责**：

| 页面 | 核心职责 | 依赖的 Providers |
|------|----------|-----------------|
| HomePage | 矩阵布局、滚动控制、悬浮按钮 | ItemProvider, CategoryProvider |
| CategoryManagementPage | 分类列表、编辑弹窗 | CategoryProvider |
| ItemDetailPage | 任务详情展示、编辑模式切换 | ItemProvider |
| SettingsPage | 设置项列表、清除数据确认 | StorageService |

**解耦方式**：

```dart
// 页面只负责布局，逻辑交给 Provider
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemNotifierProvider);
    final categories = ref.watch(categoryNotifierProvider);
    
    return itemsAsync.when(
      data: (items) => DateStreamMatrix(...),
      loading: () => LoadingWidget(),
      error: (e, _) => ErrorWidget(e),
    );
  }
}
```

### B.5 widgets 层

**纯展示组件（StatelessWidget）**：

```dart
// 只接收参数，不依赖 Provider
class TaskCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  
  @override
  Widget build(BuildContext context) { ... }
}
```

**容器组件（ConsumerWidget）**：

```dart
// 依赖 Provider，但不包含业务逻辑
class DateStreamMatrix extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    // 只负责根据状态构建不同的布局
  }
}
```

### B.6 utils 层

```dart
// date_utils.dart
class DateUtils {
  static DateTime get today => DateTime.now().startOfDay;
  static bool isSameDay(DateTime a, DateTime b);
  static List<DateTime> getDateRange(DateTime start, int days);
  static String formatRelative(DateTime date); // "今天", "明天"
}

// constants.dart
class AppConstants {
  static const maxCategoryNameLength = 10;
  static const maxItemTitleLength = 100;
  static const maxImageSizeMB = 10;
  static const daysBeforeDue = 3; // 截止前3天显示
}
```

### B.7 页面与业务逻辑的解耦方式

**原则**：页面层只负责"响应状态变化构建 UI"，业务逻辑全部下沉到 Provider

**具体做法**：

1. **事件上报**：页面只上报用户事件，不处理逻辑
```dart
// 页面层
onTap: () => ref.read(itemNotifierProvider.notifier).toggleComplete(item.id)

// Provider 层处理逻辑
Future<void> toggleComplete(String id) async {
  final item = await _storage.getItem(id);
  final updated = item.copyWith(
    status: item.status == pending ? completed : pending,
  );
  await _storage.saveItem(updated);
  ref.invalidateSelf(); // 刷新状态
}
```

2. **状态订阅**：页面通过 ref.watch 订阅状态，自动重建
```dart
final items = ref.watch(itemNotifierProvider); // 自动重建
```

3. **导航解耦**：页面不直接导航，通过回调或事件总线
```dart
// 不推荐
Navigator.push(context, ...);

// 推荐
context.go('/item/${item.id}'); // 使用 go_router，导航配置集中管理
```

---

## C. 数据设计

### C.1 最终字段定义

**Category 表（Hive）**：

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | String | PK, UUID | 主键 |
| name | String | 非空, max 10 | 分类名称 |
| color | String | 非空, hex | 颜色值 |
| sortOrder | int | 非空, default 0 | 排序权重 |
| createdAt | int | 非空 | Unix 时间戳（毫秒） |
| updatedAt | int | 非空 | Unix 时间戳（毫秒） |

**Item 表（Hive）**：

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | String | PK, UUID | 主键 |
| title | String | 非空, max 100 | 任务标题 |
| description | String? | 可选, max 500 | 描述 |
| categoryId | String | FK | 关联 Category.id |
| dueDate | int | 非空 | 截止日期（Unix 毫秒，时分秒为0） |
| dueTime | int? | 可选 | 截止时间（当天毫秒数，如 14:00 = 50400000） |
| priority | int | 非空, default 1 | 0=high, 1=medium, 2=low |
| status | int | 非空, default 0 | 0=pending, 1=completed |
| imagePath | String? | 可选 | 图片本地路径 |
| createdAt | int | 非空 | Unix 时间戳（毫秒） |
| updatedAt | int | 非空 | Unix 时间戳（毫秒） |

**AI_Log 表（可选，MVP 可延后）**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | UUID |
| itemId | String | 关联 Item.id |
| rawInput | String | 原始输入（文本或图片路径） |
| inputType | int | 0=text, 1=image |
| parsedTitle | String | 解析出的标题 |
| parsedDate | int? | 解析出的日期 |
| predictedCategoryId | String? | 推荐分类 |
| confidence | double | 置信度 0-1 |
| userCorrected | bool | 用户是否修改 |
| createdAt | int | Unix 时间戳 |

### C.2 字段类型与约束

**枚举定义**：

```dart
enum Priority { high, medium, low }
enum ItemStatus { pending, completed }
enum InputType { text, image }
```

**Hive Adapter 注册**：

```dart
// main.dart
void main() async {
  await Hive.initFlutter();
  
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(PriorityAdapter());
  Hive.registerAdapter(ItemStatusAdapter());
  
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Item>('items');
  
  runApp(ProviderScope(child: MyApp()));
}
```

### C.3 本地存储结构

**Hive Box 设计**：

```
Box<Category> 'categories':
  key: category.id (String)
  value: Category 对象

Box<Item> 'items':
  key: item.id (String)
  value: Item 对象
```

**索引策略**：

Hive 不支持二级索引，查询通过全表扫描 + 内存过滤：

```dart
// 按日期查询（全表扫描，MVP 数据量小可接受）
Future<List<Item>> getItemsByDate(DateTime date) async {
  final allItems = _itemBox.values.toList();
  return allItems.where((item) => 
    isSameDay(item.dueDate, date)
  ).toList();
}
```

**数据量预估**：

| 场景 | 数据量 | Hive 性能 |
|------|--------|-----------|
| 100 条任务 | < 100KB | < 10ms |
| 1000 条任务 | < 1MB | < 50ms |
| 10000 条任务 | < 10MB | < 200ms（需优化） |

### C.4 数据迁移预留方案

**版本标记**：

```dart
// 存储当前数据版本
Box 'app_metadata':
  key: 'data_version'
  value: 1 (int)
```

**迁移框架**：

```dart
class MigrationManager {
  static final Map<int, Future<void> Function()> _migrations = {
    1: () async { /* 初始版本，无需迁移 */ },
    2: () async { /* v0.3 迁移逻辑 */ },
  };

  static Future<void> migrate() async {
    final currentVersion = _getCurrentVersion();
    final targetVersion = _migrations.keys.max;
    
    for (var v = currentVersion + 1; v <= targetVersion; v++) {
      await _migrations[v]!();
    }
    
    await _setVersion(targetVersion);
  }
}
```

**MVP 预留**：
- 初始化时写入 `data_version = 1`
- 后续版本通过 MigrationManager 处理字段变更

---

## D. 首页核心实现方案

### D.1 日期流矩阵的数据组织方式

**数据模型**：

```dart
// 矩阵的一个单元格
class MatrixCell {
  final DateTime date;
  final String categoryId;
  final List<Item> items;
}

// 整个矩阵的数据结构
class MatrixData {
  final List<DateTime> dates;           // 纵向：日期列表
  final List<Category> categories;       // 横向：分类列表
  final Map<String, List<Item>> itemsByDate;  // 按日期分组的任务
}
```

**数据转换流程**：

```dart
// ItemProvider 中
MatrixData buildMatrixData() {
  final items = await _storage.getAllItems();
  final categories = await _storage.getAllCategories();
  
  // 1. 生成日期范围（今天起 30 天）
  final dates = List.generate(30, (i) => today.add(Duration(days: i)));
  
  // 2. 按日期分组任务（考虑跨天展示）
  final itemsByDate = <String, List<Item>>{};
  for (final date in dates) {
    itemsByDate[dateKey(date)] = items.where((item) => 
      shouldDisplayOnDate(item, date)
    ).toList();
  }
  
  return MatrixData(dates, categories, itemsByDate);
}

// 跨天展示判断
bool shouldDisplayOnDate(Item item, DateTime date) {
  final displayStart = item.dueDate.subtract(Duration(days: 3));
  return !date.isBefore(displayStart) && !date.isAfter(item.dueDate);
}
```

### D.2 日期列固定 + 分类列横向滚动的推荐实现

**方案选择**：CustomScrollView + Sliver

```dart
class DateStreamMatrix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧固定列：日期
        SizedBox(
          width: 80,
          child: ListView.builder(
            controller: _verticalController, // 与右侧同步
            itemCount: dates.length,
            itemBuilder: (context, index) => DateCell(date: dates[index]),
          ),
        ),
        
        // 右侧滚动区域：分类列
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalController,
            child: Column(
              children: [
                // 表头：分类标题行
                Row(
                  children: categories.map((c) => 
                    CategoryHeaderCell(category: c, width: 120)
                  ).toList(),
                ),
                
                // 内容：可纵向滚动的任务矩阵
                SizedBox(
                  height: matrixHeight,
                  child: ListView.builder(
                    controller: _verticalController2, // 需要与左侧同步
                    itemCount: dates.length,
                    itemBuilder: (context, dateIndex) {
                      return Row(
                        children: categories.map((c) =>
                          TaskCell(
                            date: dates[dateIndex],
                            categoryId: c.id,
                            width: 120,
                          )
                        ).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

**同步滚动机制**：

```dart
class _DateStreamMatrixState extends State<DateStreamMatrix> {
  final ScrollController _leftVertical = ScrollController();
  final ScrollController _rightVertical = ScrollController();
  final ScrollController _headerHorizontal = ScrollController();
  final ScrollController _contentHorizontal = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // 左右纵向滚动同步
    _leftVertical.addListener(() {
      if (_rightVertical.offset != _leftVertical.offset) {
        _rightVertical.jumpTo(_leftVertical.offset);
      }
    });
    _rightVertical.addListener(() {
      if (_leftVertical.offset != _rightVertical.offset) {
        _leftVertical.jumpTo(_rightVertical.offset);
      }
    });
    
    // 表头和内容横向滚动同步
    _headerHorizontal.addListener(() {
      if (_contentHorizontal.offset != _headerHorizontal.offset) {
        _contentHorizontal.jumpTo(_headerHorizontal.offset);
      }
    });
    _contentHorizontal.addListener(() {
      if (_headerHorizontal.offset != _contentHorizontal.offset) {
        _headerHorizontal.jumpTo(_contentHorizontal.offset);
      }
    });
  }
}
```

### D.3 表头与内容同步滚动机制

**问题**：两个独立的 ScrollView 需要保持滚动位置一致

**解决方案**：

1. **共享 ScrollController**（推荐）：
```dart
// 表头和内容使用同一个 Horizontal ScrollController
final horizontalController = ScrollController();

// 表头
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  controller: horizontalController,
  child: Row(...),
)

// 内容
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  controller: horizontalController, // 同一个 controller
  child: Column(...),
)
```

**限制**：这种方式要求表头和内容的宽度完全一致，且不能独立滚动

2. **监听同步**（实际采用）：
```dart
// 两个独立的 ScrollController，通过监听保持同步
void syncScrollControllers(ScrollController primary, ScrollController secondary) {
  primary.addListener(() {
    if (secondary.offset != primary.offset) {
      secondary.jumpTo(primary.offset);
    }
  });
}
```

### D.4 XY 轴互换实现策略

**实现方式**：数据层互换，UI 层复用同一组件

```dart
enum ViewMode { dateVertical, categoryVertical }

class MatrixData {
  final ViewMode mode;
  final List<String> primaryAxis;    // 纵向轴（日期或分类）
  final List<String> secondaryAxis;  // 横向轴（分类或日期）
  final Map<String, List<Item>> itemsByPrimary;
}

// 在 ItemProvider 中
MatrixData get matrixData {
  if (viewMode == ViewMode.dateVertical) {
    return MatrixData(
      mode: ViewMode.dateVertical,
      primaryAxis: dates.map((d) => dateKey(d)).toList(),
      secondaryAxis: categories.map((c) => c.id).toList(),
      itemsByPrimary: itemsByDate,
    );
  } else {
    return MatrixData(
      mode: ViewMode.categoryVertical,
      primaryAxis: categories.map((c) => c.id).toList(),
      secondaryAxis: dates.map((d) => dateKey(d)).toList(),
      itemsByPrimary: itemsByCategory, // 需要预计算
    );
  }
}
```

**UI 层**：

```dart
class DateStreamMatrix extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixData = ref.watch(matrixDataProvider);
    
    // 同一套 UI 组件，根据 mode 渲染不同的标签
    return Row(
      children: [
        // 左侧固定列
        FixedColumn(
          labels: matrixData.primaryAxis,
          labelBuilder: (axis) => matrixData.mode == dateVertical
            ? DateLabel(axis)  // 显示日期
            : CategoryLabel(axis),  // 显示分类
        ),
        
        // 右侧滚动区域
        ScrollableMatrix(
          headers: matrixData.secondaryAxis,
          headerBuilder: (axis) => matrixData.mode == dateVertical
            ? CategoryHeader(axis)  // 表头显示分类
            : DateHeader(axis),      // 表头显示日期
          cellBuilder: (primary, secondary) => TaskCell(
            primary: primary,
            secondary: secondary,
          ),
        ),
      ],
    );
  }
}
```

**切换动画**：

```dart
Future<void> swapAxis() async {
  // 1. 保存当前滚动位置百分比
  final scrollPercent = _verticalController.offset / _verticalController.position.maxScrollExtent;
  
  // 2. 淡出动画
  await _fadeOut();
  
  // 3. 切换模式
  ref.read(viewModeProvider.notifier).toggle();
  
  // 4. 恢复滚动位置（按比例）
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final newOffset = scrollPercent * _verticalController.position.maxScrollExtent;
    _verticalController.jumpTo(newOffset);
  });
  
  // 5. 淡入动画
  await _fadeIn();
}
```

### D.5 性能风险与降级方案

**风险 1：任务过多导致卡顿**

- **触发条件**：单个单元格 > 20 个任务
- **现象**：滚动掉帧
- **降级方案**：
```dart
// 单元格内任务截断显示
Widget buildTaskCell(List<Item> items) {
  final displayItems = items.take(5).toList();
  final remaining = items.length - 5;
  
  return Column(
    children: [
      ...displayItems.map((item) => TaskCard(item)),
      if (remaining > 0)
        TextButton(
          onPressed: () => showAllTasksDialog(items),
          child: Text('+ $remaining 更多'),
        ),
    ],
  );
}
```

**风险 2：日期范围过大导致内存溢出**

- **触发条件**：用户选择"全部"，数据量 > 1000 条
- **现象**：OOM 崩溃
- **降级方案**：
```dart
// 虚拟列表：只渲染可视区域
ListView.builder(
  itemCount: dates.length,
  cacheExtent: 3, // 只预加载上下3行
  itemBuilder: (context, index) => buildRow(index),
)
```

**风险 3：同步滚动延迟**

- **触发条件**：快速滑动时，左右列滚动不同步
- **现象**：视觉错位
- **降级方案**：
```dart
// 使用 NotificationListener 替代 addListener，减少回调频率
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification is ScrollUpdateNotification) {
      // 节流：每 16ms 最多同步一次
      _throttleSync(notification.metrics.pixels);
    }
    return false;
  },
  child: ListView(...),
)
```

---

## E. 快捷添加与 AI 链路

### E.1 文本输入链路

```
用户输入 → 点击解析 → 显示加载 → AI 解析 → 展示结果 → 用户确认 → 创建任务
```

**代码流程**：

```dart
// QuickAddProvider
Future<void> parseText(String input) async {
  state = state.copyWith(parseStatus: ParseStatus.loading);
  
  try {
    final result = await _aiService.parseText(input);
    state = state.copyWith(
      parseStatus: ParseStatus.success,
      parsedResult: result,
    );
  } catch (e) {
    state = state.copyWith(
      parseStatus: ParseStatus.error,
      errorMessage: '解析失败：$e',
    );
  }
}

// 用户确认后
Future<void> confirmAndCreate() async {
  final result = state.parsedResult!;
  
  // 1. 匹配推荐分类
  final categoryId = await _matchCategory(result.categoryHint);
  
  // 2. 创建 Item
  final item = Item(
    id: generateUuid(),
    title: result.title,
    categoryId: categoryId,
    dueDate: parseDate(result.date),
    dueTime: result.time != null ? parseTime(result.time!) : null,
    priority: result.priority ?? Priority.medium,
    status: ItemStatus.pending,
  );
  
  // 3. 保存
  await _storage.saveItem(item);
  
  // 4. 记录 AI Log（可选）
  await _logAIResult(input: state.rawInput, result: result);
  
  // 5. 刷新首页
  ref.invalidate(itemNotifierProvider);
}
```

### E.2 图片输入链路

```
选择图片 → 显示预览 → 点击解析 → OCR + 多模态识别 → 展示结果（含原图、OCR文字） → 用户编辑 → 创建任务
```

**代码流程**：

```dart
Future<void> pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 2048,  // 限制尺寸，减少上传时间
    maxHeight: 2048,
    imageQuality: 85,
  );
  
  if (picked != null) {
    // 保存到沙盒
    final savedPath = await _imageStorage.saveImage(File(picked.path));
    state = state.copyWith(selectedImagePath: savedPath);
  }
}

Future<void> parseImage() async {
  state = state.copyWith(parseStatus: ParseStatus.loading);
  
  try {
    final imageFile = _imageStorage.getImageFile(state.selectedImagePath!);
    final result = await _aiService.parseImage(imageFile);
    
    state = state.copyWith(
      parseStatus: ParseStatus.success,
      parsedResult: result,
      ocrText: result.ocrText, // 可编辑的 OCR 文字
    );
  } catch (e) {
    state = state.copyWith(
      parseStatus: ParseStatus.error,
      errorMessage: '图片识别失败：$e',
    );
  }
}
```

### E.3 OCR 与多模态解析的职责边界

**AIService 内部实现**：

```dart
class AIService {
  // 统一入口
  Future<AIParseResult> parseImage(File imageFile) async {
    // 1. 先进行 OCR（可选：本地或云端）
    final ocrText = await _performOCR(imageFile);
    
    // 2. 多模态模型解析
    final aiResult = await _callMultimodalLLM(imageFile, ocrText);
    
    // 3. 合并结果
    return AIParseResult(
      title: aiResult.title,
      date: aiResult.date,
      time: aiResult.time,
      categoryHint: aiResult.categoryHint,
      priority: aiResult.priority,
      ocrText: ocrText,  // 返回 OCR 原文供用户参考
      confidence: aiResult.confidence,
    );
  }
  
  // OCR 实现选择：
  // 方案 A：调用云端 OCR API（如阿里云 OCR）
  // 方案 B：直接让多模态模型做 OCR（通义千问 VL 自带 OCR 能力）
  // MVP 推荐方案 B，减少一次网络请求
}
```

### E.4 解析失败的兜底路径

| 失败场景 | 兜底策略 |
|----------|----------|
| 网络超时 | 提示"网络不稳定，请重试或切换到手动添加" |
| API 限流 | 提示"AI 服务繁忙，请稍后重试" |
| 解析结果为空 | 标题 = 原文前 20 字，日期 = 今天，分类 = "其他" |
| 图片格式错误 | 提示"图片格式不支持，请重新选择" |
| 图片过大 | 提示"图片超过 10MB，请压缩后重试" |

**兜底代码**：

```dart
AIParseResult _createFallbackResult(String rawInput, String? imagePath) {
  return AIParseResult(
    title: rawInput.length > 20 
      ? '${rawInput.substring(0, 20)}...' 
      : rawInput,
    date: formatDate(today),
    time: null,
    categoryHint: '其他',
    priority: Priority.medium,
    ocrText: null,
    confidence: 0.0,
  );
}
```

### E.5 结果确认后如何落库

**事务流程**：

```dart
Future<void> createItemFromParsedResult(ParsedResult result) async {
  // 1. 图片处理（如有）
  String? finalImagePath;
  if (state.selectedImagePath != null) {
    // 图片已在 pick 时保存到沙盒，直接使用
    finalImagePath = state.selectedImagePath;
  }
  
  // 2. 构建 Item
  final item = Item(
    id: const Uuid().v4(),
    title: result.title,
    description: result.ocrText, // OCR 文字存入描述
    categoryId: result.matchedCategoryId,
    dueDate: result.parsedDate,
    dueTime: result.parsedTime,
    priority: result.priority,
    status: ItemStatus.pending,
    imagePath: finalImagePath,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // 3. 保存（单条写入，无需事务）
  await _storage.saveItem(item);
  
  // 4. 清理临时状态
  state = QuickAddState.initial();
}
```

---

## F. 状态与规则落点

### F.1 截止前 3 天显示逻辑

**落点**：ItemProvider（业务逻辑层）

```dart
// ItemProvider
bool shouldDisplayOnDate(Item item, DateTime date) {
  final displayStart = item.dueDate.subtract(Duration(days: 3));
  return !date.isBefore(displayStart) && !date.isAfter(item.dueDate);
}

List<Item> getItemsForDate(DateTime date) {
  final allItems = await _storage.getAllItems();
  return allItems
    .where((item) => shouldDisplayOnDate(item, date))
    .toList();
}
```

**不在 UI 层计算的原因**：
- 规则可能变化（如改为前 5 天）
- 多处 UI 需要相同逻辑（首页矩阵、详情页时间线）
- 便于单元测试

### F.2 逾期判定逻辑

**落点**：Item 模型（计算属性）

```dart
class Item {
  // ... 字段
  
  bool get isOverdue {
    if (status == ItemStatus.completed) return false;
    return dueDate.isBefore(DateUtils.today);
  }
}
```

**使用场景**：

```dart
// TaskCard 组件
Widget build(BuildContext context) {
  final isOverdue = item.isOverdue;
  
  return Container(
    decoration: BoxDecoration(
      border: isOverdue ? Border.all(color: Colors.red) : null,
    ),
    child: Text(
      item.title,
      style: TextStyle(
        color: isOverdue ? Colors.red : null,
      ),
    ),
  );
}
```

### F.3 完成状态排序逻辑

**落点**：ItemProvider（查询时排序）

```dart
List<Item> sortItems(List<Item> items) {
  return items..sort((a, b) {
    // 1. 未完成在前，已完成在后
    if (a.status != b.status) {
      return a.status == ItemStatus.pending ? -1 : 1;
    }
    
    // 2. 逾期任务置顶
    if (a.isOverdue != b.isOverdue) {
      return a.isOverdue ? -1 : 1;
    }
    
    // 3. 优先级高 → 中 → 低
    final priorityOrder = {Priority.high: 0, Priority.medium: 1, Priority.low: 2};
    if (a.priority != b.priority) {
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    }
    
    // 4. 有截止时间的在前
    if (a.dueTime != null && b.dueTime == null) return -1;
    if (a.dueTime == null && b.dueTime != null) return 1;
    if (a.dueTime != null && b.dueTime != null) {
      return a.dueTime!.hour * 60 + a.dueTime!.minute
        .compareTo(b.dueTime!.hour * 60 + b.dueTime!.minute);
    }
    
    // 5. 创建时间早的在前
    return a.createdAt.compareTo(b.createdAt);
  });
}
```

### F.4 筛选逻辑如何组织

**落点**：ItemProvider（组合多个筛选条件）

```dart
class ItemFilter {
  final DateTimeRange? dateRange;
  final String? categoryId;
  final ItemStatus? status;
}

@riverpod
class FilteredItems extends _$FilteredItems {
  @override
  Future<List<Item>> build(ItemFilter filter) async {
    var items = await ref.watch(itemNotifierProvider.future);
    
    // 应用筛选条件
    if (filter.dateRange != null) {
      items = items.where((item) =>
        !item.dueDate.isBefore(filter.dateRange!.start) &&
        !item.dueDate.isAfter(filter.dateRange!.end)
      ).toList();
    }
    
    if (filter.categoryId != null) {
      items = items.where((item) =>
        item.categoryId == filter.categoryId
      ).toList();
    }
    
    if (filter.status != null) {
      items = items.where((item) =>
        item.status == filter.status
      ).toList();
    }
    
    return sortItems(items);
  }
}
```

**使用方式**：

```dart
// 首页
final items = ref.watch(filteredItemsProvider(ItemFilter(
  dateRange: DateTimeRange(start: today, end: today.add(30.days)),
)));

// 分类筛选
final items = ref.watch(filteredItemsProvider(ItemFilter(
  categoryId: selectedCategoryId,
)));
```

---

## G. 风险点

### G.1 矩阵滚动性能（最高风险）

**风险描述**：日期流矩阵涉及双向滚动 + 同步，在低端机上可能卡顿

**触发条件**：
- 分类数量 > 10 个
- 单个单元格任务 > 10 个
- 日期范围 > 90 天

**Fallback 方案**：

| 降级级别 | 策略 |
|----------|------|
| Level 1 | 减少动画效果，禁用阴影 |
| Level 2 | 单元格内任务截断显示（最多 5 个） |
| Level 3 | 日期列不固定，整体横向滚动 |
| Level 4 | 改为列表视图（日期展开，分类作为标签） |

**预防**：
- 第一周就完成 Task 3.1.4（矩阵滚动容器）的技术验证
- 使用 Flutter DevTools 性能面板检测帧率

### G.2 AI 服务稳定性

**风险描述**：国产 LLM API 可能出现限流、超时、返回格式异常

**触发条件**：
- 用户连续快速添加任务
- 网络波动
- API 服务端故障

**Fallback 方案**：

| 场景 | 处理 |
|------|------|
| 超时 | 3 秒后提示"解析超时，请重试或手动添加" |
| 限流 | 提示"AI 服务繁忙，请稍后重试"，提供手动添加入口 |
| 格式异常 | 兜底解析：标题 = 原文，日期 = 今天 |
| 完全不可用 | 隐藏快捷添加 Tab，只保留手动添加 |

**预防**：
- 第一周就开始 AI 服务联调
- 准备多个 API Key 轮换
- 实现本地缓存最近 100 条解析结果（相同输入直接返回）

### G.3 图片存储权限与空间

**风险描述**：用户拒绝存储权限，或图片占用空间过大

**触发条件**：
- Android 11+ 存储权限变更
- 用户连续添加大量图片

**Fallback 方案**：

| 场景 | 处理 |
|------|------|
| 权限拒绝 | 提示"需要存储权限才能保存图片，是否前往设置？" |
| 空间不足 | 提示"存储空间不足，请清理后重试" |
| 图片过大 | 自动压缩到 1080p，质量 80% |

**预防**：
- 使用 `path_provider` 获取应用专属目录，无需申请存储权限（Android 10+）
- 定期清理未引用的图片文件

### G.4 数据迁移兼容性

**风险描述**：v0.2 到 v0.3 数据结构变更，用户数据丢失

**触发条件**：
- 新增字段无默认值
- 枚举值顺序变更
- 字段类型变更

**Fallback 方案**：

```dart
// 读取时兼容旧数据
factory Item.fromJson(Map<String, dynamic> json) {
  return Item(
    id: json['id'] as String,
    title: json['title'] as String,
    // 新增字段提供默认值
    imagePath: json['imagePath'] as String?, // 旧数据可能不存在
    priority: json['priority'] != null 
      ? Priority.values[json['priority']]
      : Priority.medium, // 默认值
  );
}
```

**预防**：
- 所有新增字段必须有默认值或可为 null
- 枚举不要删除/重排已有值
- 使用 MigrationManager 处理复杂迁移

### G.5 跨平台兼容性

**风险描述**：iOS 和 Android 在图片选择、存储路径、日期格式上有差异

**触发条件**：
- iOS 图片选择返回临时路径，应用切换后失效
- Android 分区存储导致文件访问失败

**Fallback 方案**：

| 平台 | 处理 |
|------|------|
| iOS | 图片立即复制到沙盒，不依赖临时路径 |
| Android | 使用 `getApplicationDocumentsDirectory()`，不依赖外部存储 |

**预防**：
- 在两种平台上都进行完整测试
- 使用 `path_provider` 统一处理路径差异

---

## H. 开发前必须由老板拍板的决策清单

### 真正影响开发的决策

| # | 决策项 | 选项 | 影响范围 | 建议 |
|---|--------|------|----------|------|
| 1 | **AI 服务具体选型** | A. 通义千问 VL<br>B. 文心一言多模态<br>C. 讯飞星火 | AIService 实现、Prompt 模板、API 认证方式 | 建议 A，文档最全 |
| 2 | **API Key 管理方式** | A. 前端硬编码（MVP 可接受）<br>B. 环境变量 + CI 注入<br>C. 自建代理服务器 | 安全性、部署复杂度 | 建议 B，平衡安全和效率 |
| 3 | **日期范围默认值** | A. 近 7 天<br>B. 近 30 天（PRD 当前）<br>C. 全部 | 首页初始加载性能 | 建议 B，平衡性能和实用性 |
| 4 | **分类数量上限** | A. 无限制（PRD 当前）<br>B. 限制 20 个<br>C. 限制 10 个 | 首页横向滚动体验 | 建议 A，但 UI 上提示"分类过多可能影响性能" |
| 5 | **图片压缩策略** | A. 不压缩（MVP 简单）<br>B. 压缩到 1080p<br>C. 用户可选 | 存储空间、AI 上传速度 | 建议 B，节省空间和流量 |
| 6 | **逾期任务显示时长** | A. 逾期后只显示 7 天<br>B. 逾期后一直显示（PRD 当前）<br>C. 逾期后自动归档 | 数据量、用户体验 | 建议 B，MVP 简单处理 |
| 7 | **是否支持暗黑模式** | A. MVP 不做<br>B. 简单适配（跟随系统）<br>C. 完整适配 | 主题配置工作量 | 建议 B，成本低收益高 |

### 决策截止时间

以上决策需要在 **开发第 1 周结束前** 确认，否则会影响：
- Task 5.2.1（AI 服务接口封装）
- Task 1.2.3（图片存储服务）
- Task 3.2.3（任务数据 Provider 的默认日期范围）

---

## 建议先做的技术 Spike 列表

### Spike 1：矩阵滚动性能验证（2 天）

**目标**：验证日期流矩阵在低端机上的性能表现

**验证内容**：
- 30 天 × 10 个分类的矩阵滚动帧率
- 同步滚动的延迟情况
- 内存占用情况

**产出**：
- 性能测试报告
- 降级方案决策依据

**阻塞**：Task 3.1.4

### Spike 2：AI 服务联调（2 天）

**目标**：验证通义千问 VL 的解析准确率和响应时间

**验证内容**：
- 文本解析准确率（准备 50 条测试用例）
- 图片解析准确率（准备 20 张测试图片：课程表、白板、便签）
- 平均响应时间
- 并发请求限制

**产出**：
- 联调报告
- 最终 Prompt 模板
- API 封装接口设计

**阻塞**：Task 5.2.1

### Spike 3：图片存储权限验证（1 天）

**目标**：验证 iOS/Android 图片存储的权限和路径问题

**验证内容**：
- iOS 相册选择和相机拍照
- Android 10/11/12/13 的存储权限
- 图片保存后应用重启是否可读取

**产出**：
- 权限处理方案
- 路径管理规范

**阻塞**：Task 1.2.3、Task 5.1.2

### Spike 4：Hive 数据量测试（1 天）

**目标**：验证 Hive 在大数据量下的性能

**验证内容**：
- 1000 条任务数据的查询速度
- 内存占用情况
- 应用冷启动时间

**产出**：
- 性能基准数据
- 是否需要切换到 Drift 的决策依据

**阻塞**：Task 1.2.2

### Spike 推荐执行顺序

```
第 1 天：Spike 4（Hive 测试）→ 决定存储方案
第 2-3 天：Spike 2（AI 联调）→ 决定 AI 服务选型
第 4-5 天：Spike 3（图片权限）→ 决定图片存储方案
第 6-7 天：Spike 1（矩阵性能）→ 决定首页实现方案
```

---

## 附录：MVP 必做 vs 可延后

### MVP 必做（P0 + P1）

| 模块 | 功能 |
|------|------|
| 基础架构 | Flutter 项目、主题配置、Hive 存储、图片存储 |
| 分类管理 | CRUD、颜色设置 |
| 首页矩阵 | 日期流展示、分类列横向滚动、任务卡片 |
| 事项管理 | 手动添加、详情查看、编辑、删除 |
| 快捷添加 | 文本输入、AI 解析、结果预览 |
| 状态管理 | 完成状态、逾期标记 |

### 可延后（P2 + P3）

| 模块 | 功能 | 延后原因 |
|------|------|----------|
| 分类管理 | 拖拽排序 | 可通过删除重建实现 |
| 首页矩阵 | XY 轴互换 | 默认视图已满足核心需求 |
| 快捷添加 | 图片输入 | 文本输入已覆盖 80% 场景 |
| 筛选 | 时间范围、分类筛选 | 首页默认展示近 30 天已够用 |
| 设置 | 导出/导入数据 | MVP 阶段本地存储即可 |
| 测试 | Widget 测试、集成测试 | 先保证功能可用 |

---

**文档结束**

**修订记录**：
- v0.2：基于 PRD v0.2、原型说明书、任务拆解表，输出技术决策和实现方案
