import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return image?.path;
  }

  Future<String?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return image?.path;
  }

  Future<String> saveToAppStorage(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = '${appDir.path}/images/$fileName';

    await Directory('${appDir.path}/images').create(recursive: true);
    await File(sourcePath).copy(destPath);

    return destPath;
  }

  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null) return;
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
