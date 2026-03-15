import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/presentation/pages/home/widgets/collapsible_section.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;

class OverdueSection extends StatelessWidget {
  final List<Item> items;
  final Function(Item)? onToggleStatus;

  const OverdueSection({
    super.key,
    required this.items,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return CollapsibleSection(
      title: '逾期事项 (${items.length})',
      initiallyExpanded: true,
      titleColor: AppColors.overdue,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.overdue,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _OverdueItemCard(
            item: item,
            onTap: () => context.push('/items/${item.id}'),
            onToggleStatus: onToggleStatus != null
                ? () => onToggleStatus!(item)
                : null,
          );
        },
      ),
    );
  }
}

class _OverdueItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

  const _OverdueItemCard({
    required this.item,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.overdueBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.overdue, width: 0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.overdue,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (onToggleStatus != null)
                  GestureDetector(
                    onTap: onToggleStatus,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.overdue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.overdue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.overdue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '逾期 ${item.overdueDays} 天',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.overdue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            app_utils.DateUtils.formatDateShort(item.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildPriorityDot(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityDot() {
    Color color;
    switch (item.priority) {
      case ItemPriority.high:
        color = AppColors.highPriority;
        break;
      case ItemPriority.medium:
        color = AppColors.mediumPriority;
        break;
      case ItemPriority.low:
        color = AppColors.lowPriority;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
