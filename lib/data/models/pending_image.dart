import 'package:image_picker/image_picker.dart';

/// An image shown in the ÄTA form before saving.
sealed class PendingImage {
  const PendingImage();
}

/// An image already stored in the app's image folder.
final class SavedImage extends PendingImage {
  const SavedImage(this.fileName);
  final String fileName;
}

/// An image just taken or picked, not yet copied into the app.
final class NewImage extends PendingImage {
  const NewImage(this.file);
  final XFile file;
}
