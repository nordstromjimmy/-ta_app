import 'package:ata_work/ui/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/project_repository.dart';
import '../../utils/date_format.dart';
import '../core/widgets/dialogs.dart';
import '../core/widgets/empty_state.dart';
import '../project_detail/project_detail_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  void _openProject(BuildContext context, String projectId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: projectId),
      ),
    );
  }

  Future<void> _createProject(BuildContext context) async {
    final name = await showTextInputDialog(
      context,
      title: 'Nytt projekt',
      hint: '',
      confirmLabel: 'Skapa',
    );
    if (name == null || !context.mounted) return;

    final project = await context.read<ProjectRepository>().createProject(name);
    if (!context.mounted) return;
    _openProject(context, project.id);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProjectRepository>();
    final projects = repo.projects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projekt'),
        actions: [
          IconButton(
            tooltip: 'Inställningar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: projects.isEmpty
          ? const EmptyState(
              icon: Icons.folder_open_outlined,
              message: 'Inga projekt än.',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Dismissible(
                  key: ValueKey(project.id),
                  direction: DismissDirection.endToStart,
                  background: const _DeleteBackground(),
                  confirmDismiss: (_) => showConfirmDialog(
                    context,
                    title: 'Radera projekt?',
                    message:
                        '"${project.name}" och alla ätor och bilder kommer att tas bort',
                    confirmLabel: 'Radera',
                  ),
                  onDismissed: (_) => context
                      .read<ProjectRepository>()
                      .deleteProject(project.id),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.folder_outlined),
                    ),
                    title: Text(project.name),
                    subtitle: Text(
                      '${repo.ataCount(project.id)} ÄTA · '
                      'Skapad ${formatDate(project.createdAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openProject(context, project.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context),
        icon: const Icon(Icons.add),
        label: const Text('Nytt projekt'),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
    );
  }
}
