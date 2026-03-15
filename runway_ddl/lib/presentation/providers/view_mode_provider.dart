import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'view_mode_provider.g.dart';

enum ViewMode { dateVertical, categoryVertical }

@riverpod
class ViewModeNotifier extends _$ViewModeNotifier {
  @override
  ViewMode build() => ViewMode.dateVertical;

  void toggle() {
    state = state == ViewMode.dateVertical
        ? ViewMode.categoryVertical
        : ViewMode.dateVertical;
  }
}
