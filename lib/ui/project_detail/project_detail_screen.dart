import 'dart:io';

import 'package:ata_work/data/services/pdf_export_service.dart';
import 'package:ata_work/ui/core/pdf_share.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/ata.dart';
import '../../data/models/project.dart';
import '../../data/repositories/project_repository.dart';
import '../../utils/date_format.dart';
import '../ata_form/ata_form_screen.dart';
import '../core/widgets/ata_image.dart';
import '../core/widgets/dialogs.dart';
import '../core/widgets/empty_state.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  void _openForm(BuildContext context, {Ata? ata}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AtaFormScreen(projectId: projectId, ata: ata),
      ),
    );
  }

  Future<void> _rename(BuildContext context, Project project) async {
    final name = await showTextInputDialog(
      context,
      title: 'Ändra namn',
      initialValue: project.name,
    );
    if (name == null || !context.mounted) return;
    await context.read<ProjectRepository>().renameProject(project.id, name);
  }

  Future<void> _exportProject(
    BuildContext context,
    Project project,
    List<Ata> atas,
  ) {
    final pdf = context.read<PdfExportService>();
    return exportAndSharePdf(
      context,
      build: () => pdf.buildProjectPdf(project, atas),
      fileName: PdfExportService.fileName(project),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProjectRepository>();
    final project = repo.projectById(projectId);

    if (project == null) {
      return const Scaffold(body: Center(child: Text('Project not found')));
    }

    final atas = repo.atasFor(projectId);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: 'Exportera alla till PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: atas.isEmpty
                ? null
                : () => _exportProject(context, project, atas),
          ),
          IconButton(
            tooltip: 'Ändra namn',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(context, project),
          ),
        ],
      ),
      body: atas.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Inga ätor än.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: atas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ata = atas[index];
                final firstImage = ata.imageFileNames.firstOrNull;
                return _AtaCard(
                  ata: ata,
                  number: index + 1,
                  thumbnail: firstImage == null
                      ? null
                      : repo.imageFile(firstImage),
                  onTap: () => _openForm(context, ata: ata),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Ny ÄTA'),
      ),
    );
  }
}

class _AtaCard extends StatelessWidget {
  const _AtaCard({
    required this.ata,
    required this.number,
    required this.thumbnail,
    required this.onTap,
  });

  final Ata ata;
  final int number;
  final File? thumbnail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final thumbnail = this.thumbnail;
    final imageCount = ata.imageFileNames.length;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 72,
                  child: thumbnail == null
                      ? ColoredBox(
                          color: colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colors.outline,
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            AtaImage(file: thumbnail, cacheWidth: 216),
                            if (imageCount > 1)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.photo_library_outlined,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$imageCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ÄTA #$number',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      ata.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ata.description.isNotEmpty)
                      Text(
                        ata.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateTime(ata.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
