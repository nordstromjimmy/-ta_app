import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/project_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/image_storage_service.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/pdf_export_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: LocalStorageService.keys,
    ),
  );
  final images = await ImageStorageService.create();
  final storage = LocalStorageService(prefs);

  final projects = ProjectRepository(storage: storage, images: images);
  final settings = SettingsRepository(storage: storage, images: images);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: projects),
        ChangeNotifierProvider.value(value: settings),
        Provider.value(value: PdfExportService(images, settings)),
      ],
      child: const AtaApp(),
    ),
  );
}
