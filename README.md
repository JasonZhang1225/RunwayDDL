# RunwayDDL

> ⚠️ **当前状态：开发中（Alpha 阶段）**
>
> 本项目目前处于早期开发阶段，功能尚未完善，不建议用于生产环境。

## 简介

RunwayDDL 是一个以**日期纵向流**为主轴、以**分类横向跑道**并列展示任务的管理工具，支持 AI 辅助快速录入。

专为大学生、研究生及轻量协作团队设计，帮助用户同时管理"什么时候截止"和"这件事属于哪一类"两个维度。

## 核心特性

- **日期流视图**：以日期为纵向主轴，直观展示未来 30 天的任务分布
- **分类跑道**：横向分类列，快速查看某天不同类型任务的负载情况
- **逾期/历史区**：双层结构，逾期任务和历史记录一目了然
- **AI 快捷录入**：支持自然语言和图片识别，快速创建任务
- **跨平台**：基于 Flutter，支持 iOS、Android、Web 等多平台

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter |
| 语言 | Dart |
| 状态管理 | Riverpod |
| 本地存储 | Hive |
| 路由 | go_router |
| AI 接入 | 国产多模态 LLM API |

## 项目结构

```
runway_ddl/
├── lib/
│   ├── core/           # 核心配置（常量、主题、路由、工具类）
│   ├── data/           # 数据层（模型、服务）
│   ├── presentation/   # 展示层（页面）
│   └── main.dart
├── aliveDocuments/     # 活跃文档（PRD、技术规格等）
└── archieve/           # 归档文档
```

## 快速开始

### 环境要求

- Flutter SDK ^3.11.1
- Dart SDK

### 运行项目

```bash
cd runway_ddl
flutter pub get
flutter run
```

## 文档

详细文档位于 `aliveDocuments/` 目录：

- [产品文档 (PRD)](aliveDocuments/PRODUCT.md)
- [技术规格](aliveDocuments/TECH_SPEC.md)
- [任务拆解](aliveDocuments/TASK_BREAKDOWN.md)
- [构建计划](aliveDocuments/ALPHA_BUILD_PLAN.md)

## 版本

当前版本：`0.1.0-alpha.1`

## License

MIT License
