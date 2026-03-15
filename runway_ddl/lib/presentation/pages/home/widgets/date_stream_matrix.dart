import 'package:flutter/material.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;
import 'package:runway_ddl/data/models/category.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/presentation/providers/home_data_provider.dart';
import 'package:runway_ddl/presentation/pages/home/widgets/task_card.dart';

class DateStreamMatrix extends StatelessWidget {
  final MatrixData data;
  final ScrollController? horizontalController;
  final Function(Item)? onItemTap;
  final Function(Item)? onToggleStatus;

  const DateStreamMatrix({
    super.key,
    required this.data,
    this.horizontalController,
    this.onItemTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (data.categories.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateColumn(context),
            ..._buildCategoryColumns(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16),
            Text(
              '暂无分类',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateColumn(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          right: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          _buildDateHeader('日期'),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.dates.length,
              itemBuilder: (context, index) {
                final date = data.dates[index];
                return _buildDateCell(date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDateCell(DateTime date) {
    final today = app_utils.DateUtils.today();
    final isToday = app_utils.DateUtils.isSameDay(date, today);
    final weekday = _getWeekdayName(date.weekday);

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primaryLight.withOpacity(0.3) : null,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.month}/${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            weekday,
            style: TextStyle(
              fontSize: 12,
              color: isToday ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '今天',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryColumns(BuildContext context) {
    return data.categories.map((category) {
      return _buildCategoryColumn(context, category);
    }).toList();
  }

  Widget _buildCategoryColumn(BuildContext context, Category category) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          _buildCategoryHeader(category),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.dates.length,
              itemBuilder: (context, index) {
                final date = data.dates[index];
                final items = data.getItems(date, category);
                return _buildCell(date, category, items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(Category category) {
    Color categoryColor;
    try {
      final colorHex = category.color.replaceFirst('#', '');
      categoryColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      categoryColor = AppColors.uncategorized;
    }

    return Container(
      height: 48,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(DateTime date, Category category, List<Item> items) {
    final today = app_utils.DateUtils.today();
    final isToday = app_utils.DateUtils.isSameDay(date, today);

    return Container(
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primaryLight.withOpacity(0.1) : null,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
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

  String _getWeekdayName(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }
}
