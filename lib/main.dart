import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/project_repository.dart';
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

  final repository = ProjectRepository(
    storage: LocalStorageService(prefs),
    images: images,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repository),
        Provider.value(value: PdfExportService(images)),
      ],
      child: const AtaApp(),
    ),
  );
}
