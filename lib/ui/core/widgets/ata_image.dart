import 'dart:io';

import 'package:flutter/material.dart';

/// Shows a locally stored photo, with a fallback if the file is missing.
class AtaImage extends StatelessWidget {
  const AtaImage({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final File file;
  final BoxFit fit;

  /// Decode at a smaller size for thumbnails to save memory.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      file,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
