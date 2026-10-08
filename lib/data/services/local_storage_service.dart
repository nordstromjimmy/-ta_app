import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ata.dart';
import '../models/project.dart';

/// Persists projects and ÄTAs as JSON strings in shared preferences.
class LocalStorageService {
  LocalStorageService(this._prefs);

  static const _projectsKey = 'projects_v1';
  static const _atasKey = 'atas_v1';
  static const keys = {_projectsKey, _atasKey};

  final SharedPreferencesWithCache _prefs;

  List<Project> loadProjects() =>
      _readList(_projectsKey).map(Project.fromJson).toList();

  List<Ata> loadAtas() => _readList(_atasKey).map(Ata.fromJson).toList();

  Future<void> saveProjects(List<Project> projects) =>
      _writeList(_projectsKey, projects.map((p) => p.toJson()));

  Future<void> saveAtas(List<Ata> atas) =>
      _writeList(_atasKey, atas.map((a) => a.toJson()));

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _writeList(String key, Iterable<Map<String, dynamic>> items) =>
      _prefs.setString(key, jsonEncode(items.toList()));
}
