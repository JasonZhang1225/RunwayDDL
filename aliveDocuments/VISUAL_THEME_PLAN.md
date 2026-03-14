# RunwayDDL 视觉主题分层计划

**版本日期**：2026-03-14
**目标**：为 RunwayDDL 制定渐进式视觉主题实施计划
**文档集**：Alpha Baseline 1

---

## 一、视觉隐喻方向

### 1.1 两个候选隐喻

| 隐喻 | 核心元素 | 视觉特征 | 情感联想 |
|------|----------|----------|----------|
| **机场跑道** | Runway（跑道） | 条状分隔、编号、指示灯、地面标记 | 专业、有序、紧迫感 |
| **泳池泳道** | Lane（泳道） | 蓝色水面、分道线、起跳台、计时器 | 清爽、流畅、竞技感 |

### 1.2 推荐方向：机场跑道

**理由**：
1. **品牌契合**：产品名 RunwayDDL 直接关联跑道概念
2. **功能隐喻**：
   - 日期流 = 跑道延伸方向
   - 分类列 = 不同跑道（起飞/降落/滑行）
   - 任务 = 航班（有时刻表、有优先级）
   - 逾期 = 延误航班（红色警示）
3. **视觉潜力**：
   - 跑道编号 → 日期编号
   - 跑道灯 → 任务状态指示
   - 航班信息牌 → 任务卡片样式
   - 塔台视角 → 首页俯瞰视角

---

## 二、三层实施计划

### 2.1 结构阶段（Alpha）

**目标**：保留视觉隐喻骨架，不做重装饰

**实施内容**：

| 元素 | 实施方式 | 说明 |
|------|----------|------|
| 分类列 | 条状分隔 + 分类颜色边框 | 暗示跑道分隔 |
| 日期列 | 粗体编号 | 暗示跑道编号 |
| 任务卡片 | 简洁卡片 + 状态指示灯 | 暗示航班信息牌 |
| 逾期任务 | 红色边框 + 红色文字 | 暗示延误警示 |

**视觉规范**：

```dart
// 颜色
class AppColors {
  static const runwayBackground = Color(0xFFFAFAFA);     // 跑道地面色
  static const runwayDivider = Color(0xFFE0E0E0);        // 分道线
  static const runwayLight = Color(0xFF1976D2);          // 跑道灯（主色）
  static const warningLight = Color(0xFFF44336);         // 警示灯（逾期）
  static const successLight = Color(0xFF4CAF50);         // 通行灯（完成）
}

// 卡片样式
class TaskCardTheme {
  static final BoxDecoration defaultStyle = BoxDecoration(
    color: Colors.white,
    border: Border(left: BorderSide(color: categoryColor, width: 4)), // 左侧色条
    borderRadius: BorderRadius.circular(8),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
  );
  
  static final BoxDecoration overdueStyle = BoxDecoration(
    color: Color(0xFFFFEBEE),
    border: Border(left: BorderSide(color: AppColors.warningLight, width: 4)),
    borderRadius: BorderRadius.circular(8),
  );
}
```

**不做的事**：
- ❌ 跑道纹理背景
- ❌ 飞机图标
- ❌ 动态灯光效果
- ❌ 航班号样式

**验收标准**：
- 分类列有清晰的视觉分隔
- 任务卡片有状态指示（颜色边框）
- 整体简洁，信息密度高
- 不影响可读性

---

### 2.2 轻主题阶段（Beta）

**目标**：在静态外观/组件层加入第一版视觉皮肤

**实施内容**：

| 元素 | 实施方式 | 说明 |
|------|----------|------|
| 分类表头 | 跑道编号样式 | 如 "RWY-A"、"RWY-B" |
| 日期列 | 跑道标记样式 | 如 "03/14" 粗体编号 |
| 任务卡片 | 航班信息牌样式 | 标题+时间+状态灯 |
| 状态指示灯 | 跑道灯样式 | 圆点 + 发光效果 |
| 逾期区 | 延误航班区样式 | 红色背景 + 警示图标 |
| 历史区 | 已降落航班区样式 | 灰色背景 + 归档图标 |

**视觉规范**：

```dart
// 跑道编号样式
class RunwayNumberStyle {
  static TextStyle get categoryHeader => TextStyle(
    fontFamily: 'RobotoMono',  // 等宽字体
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );
  
  static TextStyle get dateNumber => TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}

// 跑道灯样式
class RunwayLight extends StatelessWidget {
  final Color color;
  final bool isActive;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: isActive ? [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 2),
        ] : null,
      ),
    );
  }
}

// 航班信息牌样式
class FlightInfoCard extends StatelessWidget {
  final Item item;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: _getStatusColor(), width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // 状态灯
          RunwayLight(color: _getStatusColor(), isActive: true),
          SizedBox(width: 8),
          // 航班信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: TextStyle(fontWeight: FontWeight.bold)),
                if (item.dueTime != null)
                  Text(_formatTime(item.dueTime!), style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**不做的事**：
- ❌ 跑道纹理背景
- ❌ 动态灯光闪烁
- ❌ 飞机动画
- ❌ 复杂阴影效果

**验收标准**：
- 跑道隐喻清晰可感知
- 视觉风格统一
- 不影响信息密度
- 不影响操作效率

---

### 2.3 深度包装阶段（v1.0+）

**目标**：在核心功能稳定后加入纹理、编号、动效

**实施内容**：

| 元素 | 实施方式 | 说明 |
|------|----------|------|
| 背景 | 跑道纹理 | 淡灰色条纹 + 中线 |
| 分类列 | 跑道地面效果 | 深色边线 + 中心灯光 |
| 任务卡片 | 3D 浮起效果 | 阴影 + 悬停动画 |
| 状态指示灯 | 动态闪烁 | 逾期任务红灯闪烁 |
| 添加按钮 | 飞机起飞动画 | 点击时飞机图标飞出 |
| XY 互换 | 视角切换动画 | 塔台视角 ↔ 侧视图 |

**视觉规范**：

```dart
// 跑道纹理背景
class RunwayBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RunwayTexturePainter(),
      child: Container(), // 内容
    );
  }
}

class RunwayTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制跑道纹理
    final paint = Paint()
      ..color = Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;
    
    // 绘制条纹
    for (var i = 0; i < size.width; i += 40) {
      canvas.drawRect(Rect.fromLTWH(i, 0, 20, size.height), paint);
    }
    
    // 绘制中心线
    final centerLinePaint = Paint()
      ..color = Color(0xFFE0E0E0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (var y = 0; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 10),
        centerLinePaint,
      );
    }
  }
}

// 动态跑道灯
class AnimatedRunwayLight extends StatefulWidget {
  final Color color;
  final bool shouldBlink;
  
  @override
  _AnimatedRunwayLightState createState() => _AnimatedRunwayLightState();
}

class _AnimatedRunwayLightState extends State<AnimatedRunwayLight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween(begin: 0.3, end: 1.0).animate(_controller);
    
    if (widget.shouldBlink) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_animation.value * 0.5),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

// 飞机起飞动画
class TakeoffAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  
  @override
  _TakeoffAnimationState createState() => _TakeoffAnimationState();
}

class _TakeoffAnimationState extends State<TakeoffAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _scale;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _position = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, -2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward().then((_) => widget.onComplete());
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _position,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(Icons.flight_takeoff, size: 32),
      ),
    );
  }
}
```

**验收标准**：
- 视觉隐喻完整
- 动画流畅不卡顿
- 不影响核心功能性能
- 可通过设置关闭动效

---

## 三、元素实施优先级

### 3.1 适合先做的元素

| 元素 | 阶段 | 理由 |
|------|------|------|
| 分类颜色边框 | 结构 | 低成本、高识别度 |
| 状态指示灯 | 结构 | 核心功能、低复杂度 |
| 逾期红色警示 | 结构 | 功能必需、视觉清晰 |
| 跑道编号样式 | 轻主题 | 纯 CSS/TextStyle |
| 航班信息牌样式 | 轻主题 | 组件级改造 |

### 3.2 必须后做的元素

| 元素 | 阶段 | 理由 |
|------|------|------|
| 跑道纹理背景 | 深度包装 | 影响性能、需要优化 |
| 动态灯光闪烁 | 深度包装 | 影响性能、可能干扰用户 |
| 飞机动画 | 深度包装 | 非核心功能、增加复杂度 |
| 视角切换动画 | 深度包装 | 依赖 XY 互换功能稳定 |

### 3.3 不能影响信息密度和可读性的元素

| 元素 | 限制 |
|------|------|
| 跑道纹理背景 | 透明度 < 10%，不能干扰文字阅读 |
| 分类列装饰 | 不能减少有效显示宽度 |
| 任务卡片装饰 | 不能增加卡片高度 |
| 状态指示灯 | 直径 ≤ 8px，不能占用过多空间 |
| 动画效果 | 时长 ≤ 300ms，不能阻塞操作 |

---

## 四、实施时间线

| 阶段 | 版本 | 时间 | 内容 |
|------|------|------|------|
| 结构阶段 | Alpha | Sprint 0-2 | 颜色边框、状态指示灯、逾期警示 |
| 轻主题阶段 | Beta | Sprint 3-4 | 跑道编号、航班信息牌、区域图标 |
| 深度包装阶段 | v1.0+ | 发布后 | 纹理背景、动态灯光、飞机动画 |

---

## 五、设计原则

### 5.1 功能优先

- 视觉设计服务于功能，不喧宾夺主
- 信息密度 > 视觉装饰
- 操作效率 > 视觉效果

### 5.2 渐进增强

- 基础功能不受视觉影响
- 高级视觉效果可关闭
- 性能降级自动触发

### 5.3 一致性

- 同类元素使用相同视觉语言
- 状态变化有对应的视觉反馈
- 颜色语义一致（红=逾期/警告，绿=完成/正常）

---

## 六、资源需求

### 6.1 设计资源

| 阶段 | 需求 |
|------|------|
| 结构阶段 | 无需设计师，开发根据规范实现 |
| 轻主题阶段 | 需要设计师定义跑道编号、航班信息牌样式 |
| 深度包装阶段 | 需要设计师设计纹理、动画分镜 |

### 6.2 技术资源

| 阶段 | 技术栈 |
|------|--------|
| 结构阶段 | Flutter 基础组件 |
| 轻主题阶段 | Flutter Theme + CustomPainter |
| 深度包装阶段 | Flutter Animation + Rive/Lottie |

---

**文档结束**

**版本记录**：

- 本文档为独立规划文档，不并入其他规格文件
- 历史版本归档于 `former/history/` 目录
