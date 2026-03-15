import 'package:flutter/material.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'item.dart';

extension ItemPriorityExtension on ItemPriority {
  Color get color {
    switch (this) {
      case ItemPriority.high:
        return AppColors.highPriority;
      case ItemPriority.medium:
        return AppColors.mediumPriority;
      case ItemPriority.low:
        return AppColors.lowPriority;
    }
  }

  String get label {
    switch (this) {
      case ItemPriority.high:
        return '高';
      case ItemPriority.medium:
        return '中';
      case ItemPriority.low:
        return '低';
    }
  }
}
