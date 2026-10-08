import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies picked photos into the app's private documents folder.
class ImageStorageService {
  ImageStorageService._(this._directory);

  final Directory _directory;

  static Future<ImageStorageService> create() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'ata_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return ImageStorageService._(dir);
  }

  File fileFor(String fileName) => File(p.join(_directory.path, fileName));

  /// Saves the image and returns its file name.
  Future<String> saveImage(XFile image) async {
    final ext = p.extension(image.path);
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}';
    await image.saveTo(fileFor(fileName).path);
    return fileName;
  }

  Future<void> deleteImage(String fileName) async {
    final file = fileFor(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
