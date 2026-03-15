import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/presentation/pages/home/widgets/collapsible_section.dart';
import 'package:runway_ddl/core/utils/date_utils.dart' as app_utils;

class HistorySection extends StatelessWidget {
  final List<Item> items;
  final Function(Item)? onToggleStatus;

  const HistorySection({
    super.key,
    required this.items,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return CollapsibleSection(
      title: '历史完成 (${items.length})',
      initiallyExpanded: false,
      titleColor: AppColors.textSecondary,
      icon: Icons.history,
      iconColor: AppColors.textSecondary,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _HistoryItemCard(
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

class _HistoryItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

  const _HistoryItemCard({
    required this.item,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.completed,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary.withOpacity(0.5),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textPrimary.withOpacity(0.3),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCompletedAt(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCompletedAt() {
    if (item.completedAt == null) return '已完成';
    return '${app_utils.DateUtils.formatDateShort(item.completedAt!)}完成';
  }
}
