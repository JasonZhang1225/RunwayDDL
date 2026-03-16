import '../../data/models/category.dart';

const Map<String, String> _categoryKeywords = {
  '作业': '个人作业',
  '实验': '个人作业',
  '论文': '个人作业',
  '复习': '个人作业',
  '考试': '个人作业',
  '小组': '小组作业',
  '汇报': '小组作业',
  '展示': '小组作业',
  '开会': '小组作业',
  '组会': '小组作业',
  '买': '采购',
  '采购': '采购',
  '下单': '采购',
  '补货': '采购',
};

class CategoryMatcher {
  static Category? findCategoryByNameHint(
    String? hint,
    List<Category> categories,
  ) {
    if (hint == null || hint.isEmpty) {
      return null;
    }

    final normalizedHint = hint.trim().toLowerCase();

    try {
      return categories.firstWhere(
        (category) =>
            category.name.toLowerCase() == normalizedHint ||
            category.name.toLowerCase().contains(normalizedHint) ||
            normalizedHint.contains(category.name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  static String? matchCategoryByKeyword(String? hint) {
    if (hint == null || hint.isEmpty) {
      return null;
    }

    for (final entry in _categoryKeywords.entries) {
      if (hint.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  static Category? findRecommendedCategory(
    String? hint,
    List<Category> categories,
  ) {
    final matchedByName = findCategoryByNameHint(hint, categories);
    if (matchedByName != null) {
      return matchedByName;
    }

    final categoryName = matchCategoryByKeyword(hint);
    if (categoryName == null) {
      return null;
    }

    try {
      return categories.firstWhere(
        (category) => category.name == categoryName,
      );
    } catch (e) {
      return null;
    }
  }
}
