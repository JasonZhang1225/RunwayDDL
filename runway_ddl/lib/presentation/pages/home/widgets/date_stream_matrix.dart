import 'package:flutter/material.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/presentation/providers/home_data_provider.dart';
import 'package:runway_ddl/presentation/providers/view_mode_provider.dart';
import 'package:runway_ddl/presentation/pages/home/widgets/task_card.dart';

const _matrixSwitchDuration = Duration(milliseconds: 220);

class DateStreamMatrix extends StatelessWidget {
  final MatrixData data;
  final ScrollController? horizontalController;
  final MatrixMetrics metrics;
  final VoidCallback? onToggleViewMode;
  final Function(Item)? onItemTap;
  final Function(Item)? onToggleStatus;

  const DateStreamMatrix({
    super.key,
    required this.data,
    required this.metrics,
    this.horizontalController,
    this.onToggleViewMode,
    this.onItemTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (data.categories.isEmpty) {
      return _buildEmptyState(context);
    }

    final totalHeight = metrics.totalHeightForCount(data.dates.length);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderColumn(context, totalHeight),
          ..._buildDataColumns(context, totalHeight),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '暂无分类',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderColumn(BuildContext context, double totalHeight) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: metrics.headerWidth,
      height: totalHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _buildOriginHeader(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.dates.length,
              itemBuilder: (context, index) {
                final date = data.dates[index];
                return _buildDateCell(context, date);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataColumns(BuildContext context, double totalHeight) {
    return data.categories.map((category) {
      return _buildCategoryColumn(context, category, totalHeight);
    }).toList();
  }

  Widget _buildCategoryColumn(
    BuildContext context,
    Category category,
    double totalHeight,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: metrics.categoryAxisWidth,
      height: totalHeight,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _buildCategoryHeader(context, category),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.dates.length,
              itemBuilder: (context, index) {
                final date = data.dates[index];
                final items = data.getItems(date, category);
                return _buildCell(context, date, category, items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginHeader() {
    return _OriginToggleHeader(
      height: metrics.headerHeight,
      onTap: onToggleViewMode,
    );
  }

  Widget _buildDateCell(BuildContext context, DateTime date) {
    final today = app_utils.DateUtils.today();
    final isToday = app_utils.DateUtils.isSameDay(date, today);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: metrics.cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : null,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: _DateAxisLabel(
        date: date,
        isToday: isToday,
        compact: false,
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, Category category) {
    final colorScheme = Theme.of(context).colorScheme;

    Color categoryColor;
    try {
      final colorHex = category.color.replaceFirst('#', '');
      categoryColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      categoryColor = AppColors.uncategorized;
    }

    return Container(
      height: metrics.headerHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: categoryColor,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    DateTime date,
    Category category,
    List<Item> items,
  ) {
    final today = app_utils.DateUtils.today();
    final isToday = app_utils.DateUtils.isSameDay(date, today);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: metrics.cellHeight,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primaryContainer.withValues(alpha: 0.18)
            : null,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: items.isEmpty
          ? const SizedBox.shrink()
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 3 ? 3 : items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return TaskCard(
                  item: item,
                  onTap: onItemTap != null ? () => onItemTap!(item) : null,
                  onToggleStatus: onToggleStatus != null
                      ? () => onToggleStatus!(item)
                      : null,
                );
              },
            ),
    );
  }
}

class TransposedMatrixData {
  final List<Category> categories;
  final List<DateTime> dates;
  final Map<String, Map<String, List<Item>>> cells;

  TransposedMatrixData({
    required this.categories,
    required this.dates,
    required this.cells,
  });

  List<Item> getItems(Category category, DateTime date) {
    final dateKey = app_utils.DateUtils.formatDate(date);
    return cells[category.id]?[dateKey] ?? [];
  }

  bool get isEmpty {
    for (final categoryCells in cells.values) {
      for (final items in categoryCells.values) {
        if (items.isNotEmpty) return false;
      }
    }
    return true;
  }
}

class DateStreamMatrixWithMode extends StatelessWidget {
  final MatrixData data;
  final ScrollController? horizontalController;
  final VoidCallback? onToggleViewMode;
  final Function(Item)? onItemTap;
  final Function(Item)? onToggleStatus;

  const DateStreamMatrixWithMode({
    super.key,
    required this.data,
    this.horizontalController,
    this.onToggleViewMode,
    this.onItemTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final viewMode =
        ViewModeScope.of(context)?.viewMode ?? ViewMode.dateVertical;
    return _ZoomableMatrixViewport(
      builder: (context, zoomScale) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final metrics = MatrixMetrics.resolve(
              viewportWidth: viewportWidth,
              categoryCount: data.categories.length,
              zoomScale: zoomScale,
            );

            final matrix = viewMode == ViewMode.categoryVertical
                ? _TransposedMatrix(
                    key: const ValueKey(ViewMode.categoryVertical),
                    data: _transposeData(data),
                    metrics: metrics,
                    horizontalController: horizontalController,
                    onToggleViewMode: onToggleViewMode,
                    onItemTap: onItemTap,
                    onToggleStatus: onToggleStatus,
                  )
                : DateStreamMatrix(
                    key: const ValueKey(ViewMode.dateVertical),
                    data: data,
                    metrics: metrics,
                    horizontalController: horizontalController,
                    onToggleViewMode: onToggleViewMode,
                    onItemTap: onItemTap,
                    onToggleStatus: onToggleStatus,
                  );

            return AnimatedSwitcher(
              duration: _matrixSwitchDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
                    child: child,
                  ),
                );
              },
              child: matrix,
            );
          },
        );
      },
    );
  }

  TransposedMatrixData _transposeData(MatrixData data) {
    final cells = <String, Map<String, List<Item>>>{};

    for (final category in data.categories) {
      cells[category.id] = {};
      for (final date in data.dates) {
        final dateKey = app_utils.DateUtils.formatDate(date);
        cells[category.id]![dateKey] = data.getItems(date, category);
      }
    }

    return TransposedMatrixData(
      categories: data.categories,
      dates: data.dates,
      cells: cells,
    );
  }
}

class ViewModeScope extends InheritedWidget {
  final ViewMode viewMode;

  const ViewModeScope({
    super.key,
    required this.viewMode,
    required super.child,
  });

  static ViewModeScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ViewModeScope>();
  }

  @override
  bool updateShouldNotify(ViewModeScope oldWidget) {
    return viewMode != oldWidget.viewMode;
  }
}

class _TransposedMatrix extends StatelessWidget {
  final TransposedMatrixData data;
  final MatrixMetrics metrics;
  final ScrollController? horizontalController;
  final VoidCallback? onToggleViewMode;
  final Function(Item)? onItemTap;
  final Function(Item)? onToggleStatus;

  const _TransposedMatrix({
    super.key,
    required this.data,
    required this.metrics,
    this.horizontalController,
    this.onToggleViewMode,
    this.onItemTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (data.categories.isEmpty) {
      return _buildEmptyState(context);
    }

    final totalHeight = metrics.totalHeightForCount(data.categories.length);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeaderColumn(context, totalHeight),
          ..._buildDateColumns(totalHeight),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '暂无分类',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeaderColumn(BuildContext context, double totalHeight) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: metrics.categoryAxisWidth,
      height: totalHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _buildOriginHeader(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.categories.length,
              itemBuilder: (context, index) {
                final category = data.categories[index];
                return _buildCategoryRowHeader(context, category);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDateColumns(double totalHeight) {
    return data.dates.map((date) {
      return Builder(
        builder: (context) => _buildDateColumn(context, date, totalHeight),
      );
    }).toList();
  }

  Widget _buildDateColumn(
    BuildContext context,
    DateTime date,
    double totalHeight,
  ) {
    final today = app_utils.DateUtils.today();
    final isToday = app_utils.DateUtils.isSameDay(date, today);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: metrics.dateAxisWidth,
      height: totalHeight,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _buildDateHeader(context, date, isToday),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.categories.length,
              itemBuilder: (context, index) {
                final category = data.categories[index];
                final items = data.getItems(category, date);
                return _buildCell(context, category, date, items, isToday);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginHeader() {
    return _OriginToggleHeader(
      height: metrics.headerHeight,
      onTap: onToggleViewMode,
    );
  }

  Widget _buildCategoryRowHeader(BuildContext context, Category category) {
    final colorScheme = Theme.of(context).colorScheme;

    Color categoryColor;
    try {
      final colorHex = category.color.replaceFirst('#', '');
      categoryColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      categoryColor = AppColors.uncategorized;
    }

    return Container(
      height: metrics.cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: categoryColor,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date, bool isToday) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: metrics.headerHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : null,
      ),
      child: _DateAxisLabel(
        date: date,
        isToday: isToday,
        compact: true,
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    Category category,
    DateTime date,
    List<Item> items,
    bool isToday,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: metrics.cellHeight,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primaryContainer.withValues(alpha: 0.18)
            : null,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: items.isEmpty
          ? const SizedBox.shrink()
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 3 ? 3 : items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return TaskCard(
                  item: item,
                  onTap: onItemTap != null ? () => onItemTap!(item) : null,
                  onToggleStatus: onToggleStatus != null
                      ? () => onToggleStatus!(item)
                      : null,
                );
              },
            ),
    );
  }
}

class _ZoomableMatrixViewport extends StatefulWidget {
  final Widget Function(BuildContext context, double zoomScale) builder;

  const _ZoomableMatrixViewport({required this.builder});

  @override
  State<_ZoomableMatrixViewport> createState() =>
      _ZoomableMatrixViewportState();
}

class _ZoomableMatrixViewportState extends State<_ZoomableMatrixViewport> {
  static const double _minScale = 0.85;
  static const double _maxScale = 1.65;

  double _zoomScale = 1.0;
  double _gestureStartScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      trackpadScrollCausesScale: true,
      onScaleStart: (_) {
        _gestureStartScale = _zoomScale;
      },
      onScaleUpdate: (details) {
        final nextScale = (_gestureStartScale * details.scale).clamp(
          _minScale,
          _maxScale,
        );

        if ((nextScale - _zoomScale).abs() < 0.001) {
          return;
        }

        setState(() {
          _zoomScale = nextScale;
        });
      },
      child: widget.builder(context, _zoomScale),
    );
  }
}

class MatrixMetrics {
  final double headerWidth;
  final double categoryAxisWidth;
  final double dateAxisWidth;
  final double headerHeight;
  final double cellHeight;

  const MatrixMetrics({
    required this.headerWidth,
    required this.categoryAxisWidth,
    required this.dateAxisWidth,
    required this.headerHeight,
    required this.cellHeight,
  });

  factory MatrixMetrics.resolve({
    required double viewportWidth,
    required int categoryCount,
    required double zoomScale,
  }) {
    final resolvedViewportWidth = viewportWidth <= 0 ? 360.0 : viewportWidth;
    final dateAxisWidth = (108.0 * zoomScale).clamp(92.0, 168.0);
    final categoryAxisWidth = _resolveCategoryAxisWidth(
      viewportWidth: resolvedViewportWidth,
      categoryCount: categoryCount,
      reservedWidth: dateAxisWidth,
      zoomScale: zoomScale,
    );

    return MatrixMetrics(
      headerWidth: dateAxisWidth,
      categoryAxisWidth: categoryAxisWidth,
      dateAxisWidth: dateAxisWidth,
      headerHeight: (64.0 * zoomScale).clamp(56.0, 88.0),
      cellHeight: (100.0 * zoomScale).clamp(82.0, 180.0),
    );
  }

  double totalHeightForCount(int rowCount) {
    if (rowCount <= 0) {
      return headerHeight;
    }

    return headerHeight + 1.0 + (rowCount * cellHeight) + (rowCount - 1);
  }

  static double _resolveCategoryAxisWidth({
    required double viewportWidth,
    required int categoryCount,
    required double reservedWidth,
    required double zoomScale,
  }) {
    final safeCount = categoryCount <= 0 ? 1 : categoryCount;
    final usableWidth = (viewportWidth - reservedWidth - 16.0).clamp(
      220.0,
      double.infinity,
    );
    final baseWidth = (usableWidth / safeCount).clamp(92.0, 180.0);

    final densityFactor = switch (safeCount) {
      <= 2 => 1.12,
      <= 4 => 1.04,
      >= 8 => 0.92,
      _ => 1.0,
    };

    return (baseWidth * densityFactor * zoomScale).clamp(88.0, 240.0);
  }
}

class _OriginToggleHeader extends StatelessWidget {
  final double height;
  final VoidCallback? onTap;

  const _OriginToggleHeader({
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Center(
          child: Icon(
            Icons.swap_horiz,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _DateAxisLabel extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool compact;

  const _DateAxisLabel({
    required this.date,
    required this.isToday,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekday = app_utils.DateUtils.weekdayLabels[date.weekday - 1];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${date.month}/${date.day}',
          style: TextStyle(
            fontSize: compact ? 13 : 14,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          weekday,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        if (isToday) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '今天',
              style: TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }
}
