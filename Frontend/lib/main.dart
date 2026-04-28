import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/storage_service.dart';
import 'services/dio_client.dart';
import 'providers/auth_provider.dart';
import 'providers/cache_sync_provider.dart';
import 'providers/theme_provider.dart';
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

class StudyCoachApp extends ConsumerStatefulWidget {
  const StudyCoachApp({super.key});

  @override
  ConsumerState<StudyCoachApp> createState() => _StudyCoachAppState();
}

class _StudyCoachAppState extends ConsumerState<StudyCoachApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start sync after first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOnAuth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final syncSvc = ref.read(cacheSyncServiceProvider);
      if (syncSvc.isRunning) syncSvc.syncNow();
    }
  }

  void _syncOnAuth() {
    // Watch auth state; start/stop sync service accordingly.
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      final syncSvc = ref.read(cacheSyncServiceProvider);
      if (next.isAuthenticated && !syncSvc.isRunning) {
        syncSvc.start();
      } else if (!next.isAuthenticated && syncSvc.isRunning) {
        syncSvc.stop();
      }
    });
    // Handle already-authenticated state on cold boot.
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      ref.read(cacheSyncServiceProvider).start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Automatically log out if a request hits a 401 and refresh fails
    DioClient.onUnauthorized = () {
      ref.read(authStateProvider.notifier).forceLogout();
    };

    return MaterialApp.router(
      title: 'AI Study Coach',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
