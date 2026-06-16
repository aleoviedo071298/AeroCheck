import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'theme.dart';

class AeroCheckApp extends StatelessWidget {
  const AeroCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AeroCheck',
      theme: buildAeroCheckTheme(Brightness.light),
      darkTheme: buildAeroCheckTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
