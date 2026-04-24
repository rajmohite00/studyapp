import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/storage_service.dart';
import 'services/dio_client.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'core_router.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await StorageService.init();
  
  // Firebase initialization is temporarily disabled for web scaffolding.
  // Requires configuring flutterfire on the actual deployment target.

  runApp(
    const ProviderScope(
      child: StudyCoachApp(),
    ),
  );
}

class StudyCoachApp extends ConsumerWidget {
  const StudyCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    // Automatically log out if a request hits a 401 and refresh fails
    DioClient.onUnauthorized = () {
      ref.read(authStateProvider.notifier).forceLogout();
    };

    return MaterialApp.router(
      title: 'AI Study Coach',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
