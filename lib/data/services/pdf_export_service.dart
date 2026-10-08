import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../utils/date_format.dart';
import '../models/ata.dart';
import '../models/company_info.dart';
import '../models/project.dart';
import '../repositories/settings_repository.dart';
import 'image_storage_service.dart';

/// Builds PDF documents for ÄTAs. Every ÄTA starts on a new page.
class PdfExportService {
  PdfExportService(this._images, this._settings);

  final ImageStorageService _images;
  final SettingsRepository _settings;

  static const _accent = PdfColors.blue800;
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
    final company = _settings.company;
    final logo = await _loadImage(company.logoFileName);

    final doc = pw.Document(
      title: 'ÄTA – ${project.name}',
      author: company.name.isEmpty ? null : company.name,
      creator: 'ÄTA',
    );

    for (final (number, ata) in items) {
      final images = await _loadImages(ata.imageFileNames);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(40, 32, 40, 28),
          header: (_) => _header(project, number, company, logo),
          footer: (context) => _footer(context, exportedAt, company),
          build: (_) => [
            pw.Text(
              ata.title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _join([
                'Skapad ${formatDateTime(ata.createdAt)}',
                if (company.contactPerson.isNotEmpty)
                  'Upprättad av ${company.contactPerson}',
              ]),
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

  // ---------- Header & footer ----------

  pw.Widget _header(
    Project project,
    int number,
    CompanyInfo company,
    pw.ImageProvider? logo,
  ) {
    final hasCompany = company.name.isNotEmpty;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) ...[
            pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(
                maxHeight: 44,
                maxWidth: 140,
              ),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                if (hasCompany)
                  pw.Text(
                    company.name,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.Text(
                  hasCompany ? 'Projekt: ${project.name}' : project.name,
                  style: hasCompany
                      ? const pw.TextStyle(fontSize: 10, color: _muted)
                      : pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'ÄTA',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: _muted,
                  letterSpacing: 1,
                ),
              ),
              pw.Text(
                '#$number',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(
    pw.Context context,
    DateTime exportedAt,
    CompanyInfo company,
  ) {
    const style = pw.TextStyle(fontSize: 8, color: _muted);

    final contactLines = [
      _join([
        company.name,
        if (company.orgNumber.isNotEmpty) 'Org.nr ${company.orgNumber}',
      ]),
      _join([company.address, company.postalLine]),
      _join([company.phone, company.email, company.website]),
    ].where((line) => line.isNotEmpty);

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final line in contactLines) pw.Text(line, style: style),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Exporterad ${formatDateTime(exportedAt)}', style: style),
              pw.Text(
                'Sida ${context.pageNumber} av ${context.pagesCount}',
                style: style,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Content ----------

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
            height: 320,
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

  // ---------- Helpers ----------

  /// Joins the non-empty parts with a middle dot.
  static String _join(List<String> parts) =>
      parts.where((p) => p.isNotEmpty).join('  ·  ');

  Future<pw.ImageProvider?> _loadImage(String? fileName) async {
    if (fileName == null) return null;
    final file = _images.fileFor(fileName);
    if (!await file.exists()) return null;
    return pw.MemoryImage(await file.readAsBytes());
  }

  Future<List<pw.ImageProvider>> _loadImages(List<String> fileNames) async {
    final images = <pw.ImageProvider>[];
    for (final name in fileNames) {
      final image = await _loadImage(name);
      if (image != null) images.add(image);
    }
    return images;
  }
}
