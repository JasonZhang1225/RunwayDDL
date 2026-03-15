import 'package:runway_ddl/data/models/item.dart';

class ParseResult {
  final String? title;
  final DateTime? date;
  final String? time;
  final String? categoryHint;
  final ItemPriority priority;
  final double confidence;
  final bool success;
  final String? ocrText;
  final String? errorMessage;

  const ParseResult({
    this.title,
    this.date,
    this.time,
    this.categoryHint,
    this.priority = ItemPriority.medium,
    this.confidence = 0.0,
    this.success = true,
    this.ocrText,
    this.errorMessage,
  });

  factory ParseResult.failed([String? error]) {
    return ParseResult(
      success: false,
      errorMessage: error,
    );
  }

  ParseResult copyWith({
    String? title,
    DateTime? date,
    String? time,
    String? categoryHint,
    ItemPriority? priority,
    double? confidence,
    bool? success,
    String? ocrText,
    String? errorMessage,
  }) {
    return ParseResult(
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      categoryHint: categoryHint ?? this.categoryHint,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      success: success ?? this.success,
      ocrText: ocrText ?? this.ocrText,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
