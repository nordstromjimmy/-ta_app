import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../utils/date_format.dart';
import '../models/ata.dart';
import '../models/project.dart';
import 'image_storage_service.dart';

/// Builds PDF documents for ÄTAs. Every ÄTA starts on a new page.
class PdfExportService {
  PdfExportService(this._images);

  final ImageStorageService _images;

  static const _accent = PdfColors.blue700;
  static const _muted = PdfColors.grey600;

  Future<Uint8List> buildAtaPdf(Project project, Ata ata, int number) =>
      _build(project, [(number, ata)]);

  /// [atas] must be in display order (oldest first) so the numbers match.
  Future<Uint8List> buildProjectPdf(Project project, List<Ata> atas) =>
      _build(project, [for (var i = 0; i < atas.length; i++) (i + 1, atas[i])]);

  static String fileName(Project project, {int? ataNumber}) {
    final safe = project.name
        .replaceAll(RegExp(r'[^\wåäöÅÄÖ\- ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final base = safe.isEmpty ? 'projekt' : safe;
    return ataNumber == null ? 'ATA_$base.pdf' : 'ATA_${base}_nr$ataNumber.pdf';
  }

  Future<Uint8List> _build(Project project, List<(int, Ata)> items) async {
    final exportedAt = DateTime.now();
    final doc = pw.Document(title: 'ÄTA – ${project.name}', creator: 'ÄTA');

    for (final (number, ata) in items) {
      final images = await _loadImages(ata.imageFileNames);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (_) => _header(project, number),
          footer: (context) => _footer(context, exportedAt),
          build: (_) => [
            pw.Text(
              ata.title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Skapad ${formatDateTime(ata.createdAt)}',
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
            pw.SizedBox(height: 16),
            if (ata.description.isNotEmpty) ...[
              _sectionTitle('Beskrivning'),
              pw.Paragraph(
                text: ata.description,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
              ),
              pw.SizedBox(height: 8),
            ],
            if (images.isNotEmpty) ...[
              _sectionTitle(
                images.length == 1 ? 'Bild' : 'Bilder (${images.length})',
              ),
              for (var i = 0; i < images.length; i++)
                _imageBlock(images[i], i + 1, images.length),
            ],
          ],
        ),
      );
    }

    return doc.save();
  }

  pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
  );

  /// Image and caption are kept together, so they never split across pages.
  pw.Widget _imageBlock(pw.ImageProvider image, int index, int total) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        children: [
          pw.Container(
            height: 330,
            alignment: pw.Alignment.center,
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
          if (total > 1)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                'Bild $index av $total',
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _header(Project project, int number) {
    final style = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 2)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(project.name, style: style)),
          pw.Text('ÄTA #$number', style: style.copyWith(color: _accent)),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context, DateTime exportedAt) {
    const style = pw.TextStyle(fontSize: 9, color: _muted);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Exporterad ${formatDateTime(exportedAt)}', style: style),
          pw.Text(
            'Sida ${context.pageNumber} av ${context.pagesCount}',
            style: style,
          ),
        ],
      ),
    );
  }

  Future<List<pw.ImageProvider>> _loadImages(List<String> fileNames) async {
    final images = <pw.ImageProvider>[];
    for (final name in fileNames) {
      final file = _images.fileFor(name);
      if (await file.exists()) {
        images.add(pw.MemoryImage(await file.readAsBytes()));
      }
    }
    return images;
  }
}
