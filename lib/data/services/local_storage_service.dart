import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ata.dart';
import '../models/company_info.dart';
import '../models/project.dart';

/// Persists app data as JSON strings in shared preferences.
class LocalStorageService {
  LocalStorageService(this._prefs);

  static const _projectsKey = 'projects_v1';
  static const _atasKey = 'atas_v1';
  static const _companyKey = 'company_v1';
  static const keys = {_projectsKey, _atasKey, _companyKey};

  final SharedPreferencesWithCache _prefs;

  // ---------- Projects & ÄTAs ----------

  List<Project> loadProjects() =>
      _readList(_projectsKey).map(Project.fromJson).toList();

  List<Ata> loadAtas() => _readList(_atasKey).map(Ata.fromJson).toList();

  Future<void> saveProjects(List<Project> projects) =>
      _writeList(_projectsKey, projects.map((p) => p.toJson()));

  Future<void> saveAtas(List<Ata> atas) =>
      _writeList(_atasKey, atas.map((a) => a.toJson()));

  // ---------- Company ----------

  CompanyInfo loadCompany() {
    final raw = _prefs.getString(_companyKey);
    if (raw == null) return const CompanyInfo();
    return CompanyInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveCompany(CompanyInfo company) =>
      _prefs.setString(_companyKey, jsonEncode(company.toJson()));

  // ---------- Helpers ----------

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _writeList(String key, Iterable<Map<String, dynamic>> items) =>
      _prefs.setString(key, jsonEncode(items.toList()));
}
