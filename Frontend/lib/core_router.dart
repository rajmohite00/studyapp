import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/session_setup_screen.dart';
import 'screens/session_active_screen.dart';
import 'screens/session_summary_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/subject_detail_screen.dart';
import 'screens/weekly_report_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/profile_screen.dart';
import 'app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuth = authState.isAuthenticated;
      final isAuthRoute = ['/login', '/signup', '/welcome', '/otp']
          .any((r) => state.matchedLocation.startsWith(r));

      if (state.matchedLocation == '/splash') return null;
      if (!isAuth && !isAuthRoute) return '/welcome';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),
      GoRoute(
        path: '/otp',
        builder: (c, s) => OtpScreen(email: s.extra as String),
      ),
      GoRoute(path: '/profile-setup', builder: (c, s) => const ProfileSetupScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/session/setup', builder: (c, s) => const SessionSetupScreen()),
      GoRoute(
        path: '/session/active',
        builder: (c, s) => SessionActiveScreen(session: s.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/session/summary',
        builder: (c, s) => SessionSummaryScreen(session: s.extra as Map<String, dynamic>),
      ),
      GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
      GoRoute(
        path: '/analytics/subject',
        builder: (c, s) => SubjectDetailScreen(subject: s.extra as String),
      ),
      GoRoute(path: '/analytics/weekly-report', builder: (c, s) => const WeeklyReportScreen()),
      GoRoute(path: '/ai/chat', builder: (c, s) => const AiChatScreen()),
      GoRoute(
        path: '/ai/quiz',
        builder: (c, s) => QuizScreen(quizData: s.extra as Map<String, dynamic>),
      ),
      GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
    ],
    errorBuilder: (c, s) => Scaffold(
      body: Center(child: Text('Page not found: ${s.error}')),
    ),
  );
});
