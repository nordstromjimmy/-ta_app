import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/ata.dart';
import '../../data/models/pending_image.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/pdf_export_service.dart';
import '../core/pdf_share.dart';
import '../core/widgets/ata_image.dart';
import '../core/widgets/dialogs.dart';

/// Creates a new ÄTA, or edits one when [ata] is given.
class AtaFormScreen extends StatefulWidget {
  const AtaFormScreen({super.key, required this.projectId, this.ata});

  final String projectId;
  final Ata? ata;

  @override
  State<AtaFormScreen> createState() => _AtaFormScreenState();
}

class _AtaFormScreenState extends State<AtaFormScreen> {
  static const _maxImageWidth = 2048.0;
  static const _imageQuality = 85;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _pageController = PageController();

  late final _titleController = TextEditingController(
    text: widget.ata?.title ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.ata?.description ?? '',
  );

  late final List<PendingImage> _images = [
    for (final name in widget.ata?.imageFileNames ?? const <String>[])
      SavedImage(name),
  ];

  int _currentImage = 0;
  bool _saving = false;

  bool get _isEditing => widget.ata != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ---------- Images ----------

  Future<void> _addImages(ImageSource source) async {
    try {
      final List<XFile> picked;
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: _maxImageWidth,
          imageQuality: _imageQuality,
        );
        picked = photo == null ? [] : [photo];
      } else {
        picked = await _picker.pickMultiImage(
          maxWidth: _maxImageWidth,
          imageQuality: _imageQuality,
        );
      }
      if (picked.isEmpty || !mounted) return;

      final firstNewIndex = _images.length;
      setState(() {
        _images.addAll(picked.map(NewImage.new));
        _currentImage = firstNewIndex;
      });
      _jumpToImage(firstNewIndex);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final what = source == ImageSource.camera ? 'kameran' : 'bildbiblioteket';
      _showMessage('Kunde inte öppna $what: ${e.message ?? e.code}');
    }
  }

  void _removeCurrentImage() {
    if (_images.isEmpty) return;
    setState(() {
      _images.removeAt(_currentImage);
      if (_currentImage >= _images.length) {
        _currentImage = _images.isEmpty ? 0 : _images.length - 1;
      }
    });
    _jumpToImage(_currentImage);
  }

  /// Waits for the PageView to rebuild, then shows [index].
  void _jumpToImage(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpToPage(index);
    });
  }

  // ---------- Actions ----------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = context.read<ProjectRepository>();
    final ata = widget.ata;

    try {
      if (ata == null) {
        await repo.addAta(
          projectId: widget.projectId,
          title: _titleController.text,
          description: _descriptionController.text,
          images: _images,
        );
      } else {
        await repo.updateAta(
          ata,
          title: _titleController.text,
          description: _descriptionController.text,
          images: _images,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Kunde inte spara: $e');
    }
  }

  Future<void> _delete() async {
    final ata = widget.ata;
    if (ata == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Ta bort ÄTA?',
      message: '"${ata.title}" och dess bilder tas bort permanent.',
      confirmLabel: 'Ta bort',
    );
    if (!confirmed || !mounted) return;

    await context.read<ProjectRepository>().deleteAta(ata);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _exportPdf() async {
    final ata = widget.ata;
    if (ata == null) return;

    final repo = context.read<ProjectRepository>();
    final project = repo.projectById(widget.projectId);
    if (project == null) return;

    final pdf = context.read<PdfExportService>();
    final number = repo.ataNumber(ata);

    await exportAndSharePdf(
      context,
      build: () => pdf.buildAtaPdf(project, ata, number),
      fileName: PdfExportService.fileName(project, ataNumber: number),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProjectRepository>();
    final files = [
      for (final image in _images)
        switch (image) {
          SavedImage(:final fileName) => repo.imageFile(fileName),
          NewImage(:final file) => File(file.path),
        },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Redigera ÄTA' : 'Ny ÄTA'),
        actions: [
          if (_isEditing) ...[
            IconButton(
              tooltip: 'Exportera till PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _saving ? null : _exportPdf,
            ),
            IconButton(
              tooltip: 'Ta bort',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ImageGallery(
              files: files,
              controller: _pageController,
              currentIndex: _currentImage,
              onPageChanged: (index) => setState(() => _currentImage = index),
              onCamera: () => _addImages(ImageSource.camera),
              onGallery: () => _addImages(ImageSource.gallery),
              onRemove: _removeCurrentImage,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Titel',
                //hintText: 't.ex. Extra uttag i köket',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Ange en titel'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 16,
              decoration: const InputDecoration(
                labelText: 'Beskrivning',
                //hintText: 'Vad ändrades och varför?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Spara'),
          ),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.files,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final List<File> files;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      final buttonStyle = OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size.fromHeight(46),
      );
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: buttonStyle,
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Ta foto'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: buttonStyle,
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Ladda upp'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: controller,
                  itemCount: files.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) => AtaImage(
                    key: ValueKey(files[index].path),
                    file: files[index],
                  ),
                ),
                if (files.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CounterBadge(
                      text: '${currentIndex + 1}/${files.length}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Ta foto'),
            ),
            TextButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Lägg till'),
            ),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              label: const Text('Ta bort bild'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
