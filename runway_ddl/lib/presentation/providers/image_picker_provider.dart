import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:runway_ddl/data/services/image_picker_service.dart';

part 'image_picker_provider.g.dart';

@riverpod
ImagePickerService imagePicker(ImagePickerRef ref) {
  return ImagePickerService();
}
