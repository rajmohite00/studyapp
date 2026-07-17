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
import 'screens/ai_chat_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/exam_planner_screen.dart';
import 'screens/exam_planner_setup_screen.dart';
import 'screens/subject_info_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/flashcards_screen.dart';

CustomTransitionPage<T> _fade<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final isAuth = auth.isAuthenticated;
      final isAuthRoute =
          ['/login', '/signup', '/welcome', '/otp'].any((r) => state.matchedLocation.startsWith(r));
      if (state.matchedLocation == '/splash') return null;
      if (!isAuth && !isAuthRoute) return '/welcome';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────
      GoRoute(path: '/splash',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const SplashScreen())),
      GoRoute(path: '/welcome',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const WelcomeScreen())),
      GoRoute(path: '/login',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const LoginScreen())),
      GoRoute(path: '/signup',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const SignupScreen())),
      GoRoute(path: '/otp',
          pageBuilder: (c, s) => _fade(context: c, state: s,
              child: OtpScreen(email: s.extra as String))),
      GoRoute(path: '/profile-setup',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const ProfileSetupScreen())),

      // ── Main shell ────────────────────────────────────
      GoRoute(path: '/home',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const HomeScreen())),

      // ── AI ────────────────────────────────────────────
      GoRoute(path: '/ai/chat',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const AiChatScreen())),
      GoRoute(path: '/ai/quiz',
          pageBuilder: (c, s) => _fade(context: c, state: s,
              child: QuizScreen(quizData: s.extra as Map<String, dynamic>))),

      // ── Exam Planner ──────────────────────────────────
      GoRoute(path: '/exam-planner',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const ExamPlannerScreen())),
      GoRoute(path: '/exam-planner/setup',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const ExamPlannerSetupScreen())),
      GoRoute(path: '/exam-planner/subject-info',
          pageBuilder: (c, s) => _fade(context: c, state: s,
              child: SubjectInfoScreen(subject: s.extra as String))),

      // ── Flashcards ────────────────────────────────────
      GoRoute(path: '/flashcards',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const FlashcardsScreen())),

      // ── Profile ───────────────────────────────────────
      GoRoute(path: '/profile',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const ProfileScreen())),
      GoRoute(path: '/change-password',
          pageBuilder: (c, s) => _fade(context: c, state: s, child: const ChangePasswordScreen())),
    ],
    errorBuilder: (c, s) => Scaffold(
      body: Center(child: Text('Page not found: ${s.error}')),
    ),
  );
});
