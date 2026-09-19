import 'package:flutter/material.dart';

import '../screens/shell/main_shell.dart';
import '../services/settings_service.dart';
import 'theme.dart';

class BloomApp extends StatelessWidget {
  const BloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: SettingsService.notifier,
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Bloom',
          debugShowCheckedModeBanner: false,
          theme: BloomTheme.light(),
          darkTheme: BloomTheme.dark(),
          themeMode: settings.themeMode,
          home: const MainShell(),
        );
      },
    );
  }
}
