# RunwayDDL 仓库整理报告

**执行日期**：2026-03-14
**文档集**：Alpha Baseline 1

---

## 一、目录创建操作

| 操作 | 目标路径 | 状态 |
|------|----------|------|
| 创建目录 | `/Users/zjg/RunwayDDL/former/history` | ✅ 完成 |
| 创建目录 | `/Users/zjg/RunwayDDL/former/patches` | ✅ 完成 |
| 创建目录 | `/Users/zjg/RunwayDDL/former/reports` | ✅ 完成 |

---

## 二、文件重命名操作

| 原文件名 | 新文件名 | 状态 |
|----------|----------|------|
| PRODUCT_v0.2.1.md | PRODUCT.md | ✅ 完成 |
| PROTOTYPE_v0.2.1.md | PROTOTYPE.md | ✅ 完成 |
| RULES_v0.2.1.md | RULES.md | ✅ 完成 |
| TECH_SPEC_v0.2.1.md | TECH_SPEC.md | ✅ 完成 |
| TASK_BREAKDOWN_v0.4.md | TASK_BREAKDOWN.md | ✅ 完成 |
| ALPHA_FREEZE_PATCH_v0.2.1.md | FREEZE_DECISIONS.md | ✅ 完成 |
| VISUAL_THEME_PLAN_v0.1.md | VISUAL_THEME_PLAN.md | ✅ 完成 |

---

## 三、文件移动操作

### 3.1 移动到 former/history

| 文件名 | 原路径 | 新路径 | 状态 |
|--------|--------|--------|------|
| PRODUCT_v0.1.md | 根目录 | former/history/ | ✅ 完成 |
| PRODUCT_v0.2.md | 根目录 | former/history/ | ✅ 完成 |
| PROTOTYPE_v0.2.md | 根目录 | former/history/ | ✅ 完成 |
| RULES_v0.2.md | 根目录 | former/history/ | ✅ 完成 |
| TECH_SPEC_v0.2.md | 根目录 | former/history/ | ✅ 完成 |
| TASK_BREAKDOWN_v0.2.md | 根目录 | former/history/ | ✅ 完成 |
| TASK_BREAKDOWN_v0.3.md | 根目录 | former/history/ | ✅ 完成 |

### 3.2 移动到 former/patches

| 文件名 | 原路径 | 新路径 | 状态 |
|--------|--------|--------|------|
| PRODUCT_v0.2.1_PATCH.md | 根目录 | former/patches/ | ✅ 完成 |
| RULES_v0.2.1_PATCH.md | 根目录 | former/patches/ | ✅ 完成 |
| TECH_SPEC_v0.2.1_PATCH.md | 根目录 | former/patches/ | ✅ 完成 |
| TASK_BREAKDOWN_v0.4_PATCH.md | 根目录 | former/patches/ | ✅ 完成 |

### 3.3 移动到 former/reports

| 文件名 | 原路径 | 新路径 | 状态 |
|--------|--------|--------|------|
| MERGE_REPORT_v0.2.1.md | 根目录 | former/reports/ | ✅ 完成 |

---

## 四、内部引用更新

### 4.1 PRODUCT.md

| 更新类型 | 原内容 | 新内容 |
|----------|--------|--------|
| 标题 | `# RunwayDDL 产品文档 PRD v0.2.1` | `# RunwayDDL 产品文档 PRD` |
| 基于文档 | `ALPHA_FREEZE_PATCH_v0.2.1.md` | `[FREEZE_DECISIONS.md](./FREEZE_DECISIONS.md)` |
| 适用范围 | `Alpha 阶段（v0.2.1 - v0.2.x）` | `Alpha 阶段` |
| 新增字段 | - | `**文档集**：Alpha Baseline 1` |

### 4.2 PROTOTYPE.md

| 更新类型 | 原内容 | 新内容 |
|----------|--------|--------|
| 标题 | `# RunwayDDL 页面原型说明书 v0.2.1` | `# RunwayDDL 页面原型说明书` |
| 基于文档 | `[PRODUCT_v0.2.1.md]`, `[ALPHA_FREEZE_PATCH_v0.2.1.md]` | `[PRODUCT.md]`, `[FREEZE_DECISIONS.md]` |
| 新增字段 | - | `**文档集**：Alpha Baseline 1` |

### 4.3 RULES.md

| 更新类型 | 原内容 | 新内容 |
|----------|--------|--------|
| 标题 | `# RunwayDDL 数据与状态规则说明书 v0.2.1` | `# RunwayDDL 数据与状态规则说明书` |
| 基于文档 | `[PRODUCT_v0.2.1.md]`, `[ALPHA_FREEZE_PATCH_v0.2.1.md]` | `[PRODUCT.md]`, `[FREEZE_DECISIONS.md]` |
| 新增字段 | - | `**文档集**：Alpha Baseline 1` |

### 4.4 TECH_SPEC.md

| 更新类型 | 原内容 | 新内容 |
|----------|--------|--------|
| 标题 | `# RunwayDDL 技术规格说明书 v0.2.1` | `# RunwayDDL 技术规格说明书` |
| 基于文档 | `[PRODUCT_v0.2.1.md]`, `[RULES_v0.2.1.md]`, `[ALPHA_FREEZE_PATCH_v0.2.1.md]` | `[PRODUCT.md]`, `[RULES.md]`, `[FREEZE_DECISIONS.md]` |
| 新增字段 | - | `**文档集**：Alpha Baseline 1` |

### 4.5 TASK_BREAKDOWN.md

| 更新类型 | 原内容 | 新内容 |
|----------|--------|--------|
| 标题 | `# RunwayDDL 任务分解说明书 v0.4` | `# RunwayDDL 任务分解说明书` |
| 基于文档 | `[PRODUCT_v0.2.1.md]`, `[TECH_SPEC_v0.2.1.md]`, `[ALPHA_FREEZE_PATCH_v0.2.1.md]` | `[PRODUCT.md]`, `[TECH_SPEC.md]`, `[FREEZE_DECISIONS.md]` |
| 新增字段 | - | `**文档集**：Alpha Baseline 1` |

### 4.6 FREEZE_DECISIONS.md

| 更新类型 | 原内容 | 新内容 |
|----------|--------|--------|
| 标题 | `# RunwayDDL Alpha 冻结补丁 v0.2.1` | `# RunwayDDL 冻结裁决文档` |
| 文档修订清单 | 旧文件名引用 | 新文件名引用 |
| 新增字段 | - | `**文档集**：Alpha Baseline 1` |

### 4.7 VISUAL_THEME_PLAN.md

| 更新类型 | 原内容 | 新内容 |
|----------|--------|--------|
| 标题 | `# RunwayDDL 视觉主题分层计划 v0.1` | `# RunwayDDL 视觉主题分层计划` |
| 新增字段 | - | `**文档集**：Alpha Baseline 1` |

---

## 五、新生成文件

| 文件名 | 说明 | 状态 |
|--------|------|------|
| DOC_INDEX.md | 文档索引，列出所有活动文档职责 | ✅ 完成 |
| ALPHA_BUILD_PLAN.md | Alpha 构建计划，版本规划 | ✅ 完成 |
| CLEANUP_REPORT.md | 本报告 | ✅ 完成 |

---

## 六、整理后根目录文件清单

| 文件名 | 类型 | 说明 |
|--------|------|------|
| PRODUCT.md | 活动文档 | 产品需求定义（产品源） |
| PROTOTYPE.md | 活动文档 | 页面原型规格（设计源） |
| RULES.md | 活动文档 | 数据与状态规则（规则源） |
| TECH_SPEC.md | 活动文档 | 技术实现规格（技术源） |
| TASK_BREAKDOWN.md | 活动文档 | 任务分解与执行（执行源） |
| FREEZE_DECISIONS.md | 活动文档 | 冻结裁决（决策源） |
| VISUAL_THEME_PLAN.md | 活动文档 | 视觉主题计划（独立规划） |
| DOC_INDEX.md | 索引文档 | 文档索引 |
| ALPHA_BUILD_PLAN.md | 计划文档 | Alpha 构建计划 |
| CLEANUP_REPORT.md | 报告文档 | 本整理报告 |
| README.md | 项目文件 | 项目说明（原有） |
| LICENSE | 项目文件 | 许可证（原有） |

---

## 七、former 目录结构

```
Former/
├── history/
│   ├── PRODUCT_v0.1.md
│   ├── PRODUCT_v0.2.md
│   ├── PROTOTYPE_v0.2.md
│   ├── RULES_v0.2.md
│   ├── TECH_SPEC_v0.2.md
│   ├── TASK_BREAKDOWN_v0.2.md
│   └── TASK_BREAKDOWN_v0.3.md
├── patches/
│   ├── PRODUCT_v0.2.1_PATCH.md
│   ├── RULES_v0.2.1_PATCH.md
│   ├── TECH_SPEC_v0.2.1_PATCH.md
│   └── TASK_BREAKDOWN_v0.4_PATCH.md
└── reports/
    └── MERGE_REPORT_v0.2.1.md
```

---

## 八、整理总结

### 8.1 完成情况

- ✅ 创建目录结构完成
- ✅ 文件重命名完成（7 个文件）
- ✅ 历史文件移动完成（7 个文件）
- ✅ Patch 文件移动完成（4 个文件）
- ✅ 报告文件移动完成（1 个文件）
- ✅ 内部引用更新完成（7 个文件）
- ✅ 新文档生成完成（3 个文件）

### 8.2 根目录状态

根目录现只保留当前开发需要的正式文档：
- 7 个活动文档（无版本文件名）
- 3 个新生成的索引/计划/报告文档
- 2 个原有项目文件（README.md, LICENSE）

### 8.3 文档集名称

当前文档集名称：**Alpha Baseline 1**

---

**文档结束**
