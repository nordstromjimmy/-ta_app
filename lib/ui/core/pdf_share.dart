import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Builds a PDF and opens the system share sheet for it.
Future<void> exportAndSharePdf(
  BuildContext context, {
  required Future<Uint8List> Function() build,
  required String fileName,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Skapar PDF…')));

  try {
    final bytes = await build();
    messenger.hideCurrentSnackBar();
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Kunde inte skapa PDF: $e')));
  }
}
