import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/storage_service.dart';
import 'services/dio_client.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'core_router.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for consistent UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar for immersive feel
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Hive.initFlutter();
  await StorageService.init();

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
    final router = ref.watch(routerProvider);

    // Automatically log out if a request hits a 401 and refresh fails
    DioClient.onUnauthorized = () {
      ref.read(authStateProvider.notifier).forceLogout();
    };

    return MaterialApp.router(
      title: 'AI Study Coach',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeModeProvider),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      scrollBehavior: _SmoothScrollBehavior(),
      routerConfig: router,
    );
  }
}

/// Use ClampingScrollPhysics on all platforms for a consistent, responsive feel.
class _SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child; // Remove the glow overscroll effect on Android
}
