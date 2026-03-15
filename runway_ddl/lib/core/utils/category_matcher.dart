import '../../data/models/category.dart';
import '../../data/models/parse_result.dart';

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

  static Category? findRecommendedCategory(String? hint, List<Category> categories) {
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

  static double calculateConfidence(String? hint, ParseResult result) {
    double score = 0.0;

    if (result.title != null && result.title!.isNotEmpty) {
      score += 0.3;
    }

    if (result.date != null) {
      score += 0.3;
    }

    if (result.categoryHint != null && result.categoryHint!.isNotEmpty) {
      final matchedCategory = matchCategoryByKeyword(result.categoryHint);
      if (matchedCategory != null) {
        score += 0.4;
      }
    }

    return score.clamp(0.0, 1.0);
  }
}
