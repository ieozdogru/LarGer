import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:larger/providers/hive_provider.dart';
import 'package:larger/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  runApp(const ProviderScope(child: LarGerApp()));
}

class LarGerApp extends StatelessWidget {
  const LarGerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LarGer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const MainLayout(),
    );
  }
}
