import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/data/models/item.dart';
import 'package:runway_ddl/data/models/item_priority_extension.dart';

class TaskCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

  const TaskCard({
    super.key,
    required this.item,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap ?? () => context.push('/items/${item.id}'),
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onToggleStatus != null)
                  GestureDetector(
                    onTap: onToggleStatus,
                    child: Container(
                      height: 18,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.priority.color,
                          width: 2,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6, top: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.priority.color,
                    ),
                  ),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: item.status == ItemStatus.completed
                          ? colorScheme.onSurface.withValues(alpha: 0.5)
                          : colorScheme.onSurface,
                      decoration: item.status == ItemStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (item.dueTime != null) ...[
              const SizedBox(height: 4),
              Text(
                item.dueTime!,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
