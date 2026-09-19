import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/firebase_options.dart';
import 'package:larger/providers/auth_provider.dart';
import 'package:larger/providers/hive_provider.dart';
import 'package:larger/screens/login_screen.dart';
import 'package:larger/screens/main_layout.dart';
import 'package:larger/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode && ref.watch(debugSessionProvider)) {
      return const MainLayout();
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        return const MainLayout();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Auth error: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
