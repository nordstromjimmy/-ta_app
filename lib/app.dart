import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/projects/projects_screen.dart';

class AtaApp extends StatelessWidget {
  const AtaApp({super.key});

  static const _seed = Color(0xFF1E88E5); // Bright blue

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ÄTA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      ),
      locale: const Locale('sv', 'SE'),
      supportedLocales: const [Locale('sv', 'SE')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const ProjectsScreen(),
    );
  }
}
