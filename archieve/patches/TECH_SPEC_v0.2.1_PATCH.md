# RunwayDDL TECH_SPEC v0.2.1 修订建议

**版本日期**：2026-03-14
**基于**：ALPHA_FREEZE_PATCH_v0.2.1 老板冻结裁决

---

## 一、需修订章节清单

| 章节 | 修订类型 | 优先级 |
|------|----------|--------|
| C.1 最终字段定义 | 新增字段 | P0 |
| D.1 日期流矩阵数据组织 | 重写 | P0 |
| F.4 筛选逻辑 | 移除 Alpha | P0 |
| 附录 MVP 必做 vs 可延后 | 重写 | P0 |
| 新增：首页双层展示结构 | 新增章节 | P0 |

---

## 二、章节修订详情

### 修订 1：C.1 最终字段定义

**原内容位置**：TECH_SPEC_v0.2.md 第 483-525 行

**修订后内容**：

```markdown
### C.1 最终字段定义

**Category 表（Hive）**：

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | String | PK, UUID | 主键，系统内置分类使用固定 ID |
| name | String | 非空, max 10 | 分类名称 |
| color | String | 非空, hex | 颜色值 |
| sortOrder | int | 非空, default 0 | 排序权重 |
| isSystem | bool | 非空, default false | 是否系统内置分类 |
| createdAt | int | 非空 | Unix 时间戳（毫秒） |
| updatedAt | int | 非空 | Unix 时间戳（毫秒） |

**系统内置分类**：

| id | name | color | isSystem |
|----|------|-------|----------|
| uncategorized | 未分类 | #9E9E9E | true |

**Item 表（Hive）**：

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | String | PK, UUID | 主键 |
| title | String | 非空, max 100 | 任务标题 |
| description | String? | 可选, max 500 | 描述 |
| categoryId | String | FK, 非空 | 关联 Category.id，默认 "uncategorized" |
| dueDate | int | 非空 | 截止日期（Unix 毫秒，时分秒为0） |
| dueTime | int? | 可选 | 截止时间（当天毫秒数，如 14:00 = 50400000） |
| priority | int | 非空, default 1 | 0=high, 1=medium, 2=low |
| status | int | 非空, default 0 | **只有 0=pending, 1=completed** |
| imagePath | String? | 可选 | 图片本地路径 |
| createdAt | int | 非空 | Unix 时间戳（毫秒） |
| updatedAt | int | 非空 | Unix 时间戳（毫秒） |

**重要说明**：

1. **不存在 overdue 字段**：逾期状态为运行时计算
2. **status 只有两种值**：0 (pending) 或 1 (completed)
3. **categoryId 必填**：默认值为 "uncategorized"

**计算属性（不存储）**：

```dart
class Item {
  // ... 存储字段
  
  // 计算属性
  bool get isOverdue => status == ItemStatus.pending && dueDate.isBefore(DateUtils.today);
  
  DisplayArea get displayArea {
    if (dueDate.isBefore(DateUtils.today)) {
      return status == ItemStatus.completed ? DisplayArea.history : DisplayArea.overdue;
    }
    return DisplayArea.mainStream;
  }
  
  int get overdueDays {
    if (!isOverdue) return 0;
    return DateUtils.today.difference(dueDate).inDays;
  }
}

enum DisplayArea { mainStream, overdue, history }
```
```

---

### 修订 2：新增章节 - 首页双层展示结构

**插入位置**：TECH_SPEC_v0.2.md D.1 节之前

**新增内容**：

```markdown
### D.0 首页双层展示结构

#### D.0.1 结构定义

```dart
enum DisplayArea { mainStream, overdue, history }

class HomePageData {
  final List<Item> overdueItems;      // 逾期区事项
  final List<Item> historyItems;      // 历史区事项
  final MatrixData mainStreamMatrix;  // 主日期流矩阵
}

class MatrixData {
  final List<DateTime> dates;           // 今天起 30 天
  final List<Category> categories;       // 所有分类（含未分类）
  final Map<String, List<Item>> itemsByDate;  // 按日期分组的任务
}
```

#### D.0.2 数据组织方式

**ItemProvider 核心方法**：

```dart
@riverpod
class ItemNotifier extends _$ItemNotifier {
  
  // 获取首页完整数据
  HomePageData getHomePageData() {
    final allItems = _storage.getAllItems();
    final today = DateUtils.today;
    
    // 1. 分类到不同区域
    final overdueItems = <Item>[];
    final historyItems = <Item>[];
    final futureItems = <Item>[];
    
    for (final item in allItems) {
      if (item.dueDate.isBefore(today)) {
        if (item.status == ItemStatus.completed) {
          historyItems.add(item);
        } else {
          overdueItems.add(item);
        }
      } else {
        futureItems.add(item);
      }
    }
    
    // 2. 排序
    overdueItems.sort(_compareOverdueItems);
    historyItems.sort(_compareHistoryItems);
    
    // 3. 构建主日期流矩阵
    final matrix = _buildMatrix(futureItems);
    
    return HomePageData(
      overdueItems: overdueItems,
      historyItems: historyItems,
      mainStreamMatrix: matrix,
    );
  }
  
  // 逾期区排序：逾期天数倒序 > 优先级 > 截止时间
  int _compareOverdueItems(Item a, Item b) {
    final overdueDaysA = today.difference(a.dueDate).inDays;
    final overdueDaysB = today.difference(b.dueDate).inDays;
    
    if (overdueDaysA != overdueDaysB) {
      return overdueDaysB.compareTo(overdueDaysA); // 倒序
    }
    
    // 同逾期天数按优先级
    final priorityOrder = {Priority.high: 0, Priority.medium: 1, Priority.low: 2};
    if (a.priority != b.priority) {
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    }
    
    // 同优先级按截止时间
    return a.dueDate.compareTo(b.dueDate);
  }
  
  // 历史区排序：完成时间倒序
  int _compareHistoryItems(Item a, Item b) {
    return b.updatedAt.compareTo(a.updatedAt);
  }
  
  // 构建主日期流矩阵
  MatrixData _buildMatrix(List<Item> futureItems) {
    final today = DateUtils.today;
    final dates = List.generate(30, (i) => today.add(Duration(days: i)));
    final categories = _storage.getAllCategories();
    
    final itemsByDate = <String, List<Item>>{};
    for (final date in dates) {
      final dateKey = DateUtils.dateKey(date);
      itemsByDate[dateKey] = futureItems
        .where((item) => _shouldDisplayOnDate(item, date))
        .toList();
      itemsByDate[dateKey]!.sort(_compareMainStreamItems);
    }
    
    return MatrixData(dates, categories, itemsByDate);
  }
}
```

#### D.0.3 状态变更后的区域迁移

```dart
Future<void> toggleComplete(String id) async {
  final item = await _storage.getItem(id);
  final updated = item.copyWith(
    status: item.status == ItemStatus.pending 
      ? ItemStatus.completed 
      : ItemStatus.pending,
    updatedAt: DateTime.now(),
  );
  
  await _storage.saveItem(updated);
  
  // 自动触发区域迁移（Provider 重新计算）
  ref.invalidateSelf();
}

Future<void> updateDueDate(String id, DateTime newDueDate) async {
  final item = await _storage.getItem(id);
  final updated = item.copyWith(
    dueDate: newDueDate,
    updatedAt: DateTime.now(),
  );
  
  await _storage.saveItem(updated);
  
  // 自动触发区域迁移（Provider 重新计算）
  ref.invalidateSelf();
}
```

#### D.0.4 UI 层实现

```dart
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homePageDataProvider);
    
    return CustomScrollView(
      slivers: [
        // 固定区域：逾期区 + 历史区
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (homeData.overdueItems.isNotEmpty)
                OverdueSection(items: homeData.overdueItems),
              if (homeData.historyItems.isNotEmpty)
                HistorySection(items: homeData.historyItems),
            ],
          ),
        ),
        
        // 主日期流矩阵
        SliverToBoxAdapter(
          child: DateStreamMatrix(data: homeData.mainStreamMatrix),
        ),
      ],
    );
  }
}
```
```

---

### 修订 3：D.1 日期流矩阵数据组织方式

**原内容位置**：TECH_SPEC_v0.2.md 第 633-679 行

**修订后内容**：

```markdown
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
  final List<DateTime> dates;           // 今天起 30 天（固定）
  final List<Category> categories;       // 所有分类
  final Map<String, List<Item>> itemsByDate;  // 按日期分组的任务
}
```

**数据转换流程**：

```dart
// ItemProvider 中
MatrixData buildMatrix(List<Item> futureItems) {
  final categories = _storage.getAllCategories();
  
  // 1. 生成日期范围（固定：今天起 30 天）
  final today = DateUtils.today;
  final dates = List.generate(30, (i) => today.add(Duration(days: i)));
  
  // 2. 按日期分组任务（考虑跨天展示）
  final itemsByDate = <String, List<Item>>{};
  for (final date in dates) {
    final dateKey = DateUtils.dateKey(date);
    itemsByDate[dateKey] = futureItems
      .where((item) => shouldDisplayOnDate(item, date))
      .toList();
    // 排序
    itemsByDate[dateKey]!.sort(_compareMainStreamItems);
  }
  
  return MatrixData(dates, categories, itemsByDate);
}

// 跨天展示判断
bool shouldDisplayOnDate(Item item, DateTime date) {
  final displayStart = item.dueDate.subtract(Duration(days: 3));
  return !date.isBefore(displayStart) && !date.isAfter(item.dueDate);
}

// 主日期流排序
int _compareMainStreamItems(Item a, Item b) {
  // 1. 未完成在前，已完成在后
  if (a.status != b.status) {
    return a.status == ItemStatus.pending ? -1 : 1;
  }
  
  // 2. 优先级高 → 中 → 低
  final priorityOrder = {Priority.high: 0, Priority.medium: 1, Priority.low: 2};
  if (a.priority != b.priority) {
    return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
  }
  
  // 3. 截止时间早的在前
  if (a.dueTime != null && b.dueTime == null) return -1;
  if (a.dueTime == null && b.dueTime != null) return 1;
  if (a.dueTime != null && b.dueTime != null) {
    return a.dueTime!.compareTo(b.dueTime!);
  }
  
  // 4. 创建时间早的在前
  return a.createdAt.compareTo(b.createdAt);
}
```

**Alpha 阶段限制**：
- 日期范围固定为 30 天，不支持筛选
- 分类固定显示全部，不支持筛选
```

---

### 修订 4：F.4 筛选逻辑如何组织

**原内容位置**：TECH_SPEC_v0.2.md 第 1282-1336 行

**修订后内容**：

```markdown
### F.4 筛选逻辑如何组织

> **Alpha 阶段说明**：筛选功能推迟到 Beta 版本实现

**Alpha 替代方案**：

```dart
// Alpha 阶段：固定数据范围，无需筛选
@riverpod
class HomePageData extends _$HomePageData {
  @override
  Future<HomePageDataModel> build() async {
    final allItems = await _storage.getAllItems();
    final today = DateUtils.today;
    
    // 固定分类：逾期区、历史区、主日期流
    final overdueItems = allItems
      .where((item) => item.dueDate.isBefore(today) && item.status == ItemStatus.pending)
      .toList();
    
    final historyItems = allItems
      .where((item) => item.dueDate.isBefore(today) && item.status == ItemStatus.completed)
      .toList();
    
    final futureItems = allItems
      .where((item) => !item.dueDate.isBefore(today))
      .toList();
    
    // 固定日期范围：今天起 30 天
    final matrix = buildMatrix(futureItems);
    
    return HomePageDataModel(
      overdueItems: sortOverdueItems(overdueItems),
      historyItems: sortHistoryItems(historyItems),
      mainStreamMatrix: matrix,
    );
  }
}
```

**Beta 阶段筛选逻辑（预留）**：

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
```

---

### 修订 5：附录 MVP 必做 vs 可延后

**原内容位置**：TECH_SPEC_v0.2.md 第 1556-1582 行

**修订后内容**：

```markdown
## 附录：MVP 必做 vs 可延后

### Alpha 必做（P0 + P1）

| 模块 | 功能 | 说明 |
|------|------|------|
| 基础架构 | Flutter 项目、主题配置、Hive 存储 | 基础设施 |
| 基础架构 | 图片存储服务 | 图片输入链路依赖 |
| 分类管理 | CRUD、颜色设置、系统"未分类" | 含系统内置分类 |
| 首页双层结构 | 逾期区、历史区、主日期流 | 核心展示结构 |
| 首页矩阵 | 日期流展示、分类列横向滚动、任务卡片 | 主日期流部分 |
| 事项管理 | 手动添加、详情查看、编辑、删除 | 基础 CRUD |
| 快捷添加 | 文本输入、AI 解析、结果预览 | 文本链路 |
| 快捷添加 | 图片输入、相册选择、拍照、权限处理 | 图片链路（Alpha 必做） |
| 状态管理 | 完成状态、逾期计算、区域迁移 | 逾期为计算状态 |

### Alpha 后段（P1）

| 模块 | 功能 | 说明 |
|------|------|------|
| 首页矩阵 | XY 轴互换 | 在默认视图稳定后实现 |

### Beta 功能（原 Alpha P2）

| 模块 | 功能 | 延后原因 |
|------|------|----------|
| 筛选 | 时间范围筛选 | 历史/逾期区已承接过去日期 |
| 筛选 | 分类筛选 | Alpha 固定显示全部分类 |
| 筛选 | 状态筛选 | Alpha 无筛选入口 |
| 分类管理 | 拖拽排序 | 可通过删除重建实现 |
| 设置 | 导出/导入数据 | Alpha 阶段本地存储即可 |
| 测试 | Widget 测试、集成测试 | 先保证功能可用 |

### 明确不做（Alpha/Beta）

| 功能 | 原因 |
|------|------|
| overdue 持久化 | 老板裁决：仅计算状态 |
| 过去日期回插主日期流 | 老板裁决：通过历史/逾期区承接 |
```

---

## 三、影响分析

### 3.1 对数据模型的影响

| 变更 | 影响 |
|------|------|
| Category 增加 isSystem 字段 | 需要迁移现有数据，新增字段有默认值 |
| Item.status 只有 pending/completed | 无影响，原本就是这两种 |
| 移除 overdue 持久化 | 无影响，原本就没有这个字段 |
| categoryId 默认 "uncategorized" | 需要初始化系统分类 |

### 3.2 对 Provider 逻辑的影响

| Provider | 变更 |
|----------|------|
| ItemProvider | 新增 getHomePageData() 方法，返回三层结构数据 |
| ItemProvider | 新增区域排序方法（逾期区、历史区） |
| ItemProvider | 移除筛选相关方法（Alpha） |
| CategoryProvider | 新增系统分类初始化逻辑 |
| QuickAddProvider | 无变更 |

### 3.3 对首页渲染的影响

| 组件 | 变更 |
|------|------|
| HomePage | 新增双层结构：固定区域 + 主日期流 |
| 新增 OverdueSection | 逾期区组件 |
| 新增 HistorySection | 历史区组件 |
| DateStreamMatrix | 日期范围固定 30 天，移除筛选逻辑 |
| 移除筛选栏 | Alpha 不显示 |

### 3.4 对 Quick Add 链路的影响

| 链路 | 变更 |
|------|------|
| 文本输入 | 无变更 |
| 图片输入 | 从"可延后"变为"Alpha 必做" |
| AI 解析 | 无变更 |
| 日期选择 | 允许选择过去日期 |

---

## 四、新增技术 Spike 建议

### Spike 5：首页双层结构性能验证（1 天）

**目标**：验证首页双层结构的渲染性能

**验证内容**：
- 逾期区 + 历史区 + 主日期流的整体渲染时间
- 区域展开/折叠的动画性能
- 状态变更后区域迁移的刷新性能

**产出**：
- 性能测试报告
- 是否需要虚拟列表的决策依据

**阻塞**：首页双层结构实现

---

**文档结束**

**修订记录**：
- v0.2.1：基于老板冻结裁决，新增首页双层结构设计，明确 overdue 为计算状态，新增系统分类字段，移除 Alpha 筛选逻辑，更新 MVP 范围
