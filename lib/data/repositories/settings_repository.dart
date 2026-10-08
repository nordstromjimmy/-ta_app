import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/company_info.dart';
import '../services/image_storage_service.dart';
import '../services/local_storage_service.dart';

/// Holds the company details and logo.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository({
    required LocalStorageService storage,
    required ImageStorageService images,
  }) : _storage = storage,
       _images = images,
       _company = storage.loadCompany();

  final LocalStorageService _storage;
  final ImageStorageService _images;

  CompanyInfo _company;

  CompanyInfo get company => _company;

  File? get logoFile {
    final fileName = _company.logoFileName;
    return fileName == null ? null : _images.fileFor(fileName);
  }

  /// Saves [info]. Its own logoFileName is ignored: pass [newLogo] to
  /// replace the logo, or [removeLogo] to clear it.
  Future<void> saveCompany(
    CompanyInfo info, {
    XFile? newLogo,
    bool removeLogo = false,
  }) async {
    final oldLogo = _company.logoFileName;

    final String? logo;
    if (newLogo != null) {
      logo = await _images.saveImage(newLogo);
    } else if (removeLogo) {
      logo = null;
    } else {
      logo = oldLogo;
    }

    _company = info.withLogo(logo);
    notifyListeners();
    await _storage.saveCompany(_company);

    if (oldLogo != null && oldLogo != logo) {
      await _images.deleteImage(oldLogo);
    }
  }
}
