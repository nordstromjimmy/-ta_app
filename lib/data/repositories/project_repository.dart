import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/ata.dart';
import '../models/pending_image.dart';
import '../models/project.dart';
import '../services/image_storage_service.dart';
import '../services/local_storage_service.dart';

/// Single source of truth for projects and ÄTAs.
///
/// The UI listens to this repository. Every change updates memory first,
/// notifies listeners, and then persists the data to local storage.
class ProjectRepository extends ChangeNotifier {
  ProjectRepository({
    required LocalStorageService storage,
    required ImageStorageService images,
  }) : _storage = storage,
       _images = images,
       _projects = storage.loadProjects(),
       _atas = storage.loadAtas();

  final LocalStorageService _storage;
  final ImageStorageService _images;

  List<Project> _projects;
  List<Ata> _atas;

  // ---------- Reads ----------

  /// Newest project first.
  List<Project> get projects => List.unmodifiable(
    [..._projects]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  Project? projectById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  /// Oldest first, so the ÄTAs can be numbered #1, #2, #3…
  List<Ata> atasFor(String projectId) => List.unmodifiable(
    _atas.where((a) => a.projectId == projectId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
  );

  int ataCount(String projectId) =>
      _atas.where((a) => a.projectId == projectId).length;

  int ataNumber(Ata ata) =>
      atasFor(ata.projectId).indexWhere((a) => a.id == ata.id) + 1;

  File imageFile(String fileName) => _images.fileFor(fileName);

  // ---------- Projects ----------

  Future<Project> createProject(String name) async {
    final project = Project(
      id: _newId(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    _projects = [..._projects, project];
    notifyListeners();
    await _storage.saveProjects(_projects);
    return project;
  }

  Future<void> renameProject(String id, String name) async {
    _projects = [
      for (final p in _projects) p.id == id ? p.copyWith(name: name.trim()) : p,
    ];
    notifyListeners();
    await _storage.saveProjects(_projects);
  }

  Future<void> deleteProject(String id) async {
    final removedAtas = _atas.where((a) => a.projectId == id).toList();
    _projects = _projects.where((p) => p.id != id).toList();
    _atas = _atas.where((a) => a.projectId != id).toList();
    notifyListeners();

    await Future.wait([
      _storage.saveProjects(_projects),
      _storage.saveAtas(_atas),
    ]);
    await _deleteImages(removedAtas.expand((a) => a.imageFileNames));
  }

  // ---------- ÄTAs ----------

  Future<void> addAta({
    required String projectId,
    required String title,
    required String description,
    List<PendingImage> images = const [],
  }) async {
    final imageFileNames = await _persistImages(images);

    final ata = Ata(
      id: _newId(),
      projectId: projectId,
      title: title.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
      imageFileNames: imageFileNames,
    );
    _atas = [..._atas, ata];
    notifyListeners();
    await _storage.saveAtas(_atas);
  }

  /// [images] is the complete new list, in order. Saved images missing
  /// from it are deleted from disk.
  Future<void> updateAta(
    Ata ata, {
    required String title,
    required String description,
    required List<PendingImage> images,
  }) async {
    final imageFileNames = await _persistImages(images);

    final updated = Ata(
      id: ata.id,
      projectId: ata.projectId,
      title: title.trim(),
      description: description.trim(),
      createdAt: ata.createdAt,
      imageFileNames: imageFileNames,
    );
    _atas = [for (final a in _atas) a.id == ata.id ? updated : a];
    notifyListeners();
    await _storage.saveAtas(_atas);

    await _deleteImages(
      ata.imageFileNames.where((name) => !imageFileNames.contains(name)),
    );
  }

  Future<void> deleteAta(Ata ata) async {
    _atas = _atas.where((a) => a.id != ata.id).toList();
    notifyListeners();
    await _storage.saveAtas(_atas);
    await _deleteImages(ata.imageFileNames);
  }

  // ---------- Helpers ----------

  /// Copies new images into the app folder and returns all file names.
  Future<List<String>> _persistImages(List<PendingImage> images) async => [
    for (final image in images)
      switch (image) {
        SavedImage(:final fileName) => fileName,
        NewImage(:final file) => await _images.saveImage(file),
      },
  ];

  Future<void> _deleteImages(Iterable<String> fileNames) async {
    for (final name in fileNames.toList()) {
      await _images.deleteImage(name);
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
