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
import 'screens/exam_planner_screen.dart';
import 'screens/exam_planner_setup_screen.dart';
import 'screens/subject_info_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/virtual_library_screen.dart';

// ── Smooth fade+slide transition ──────────────────────────────────────────────
CustomTransitionPage<T> _slideFade<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  Offset begin = const Offset(0.03, 0),
}) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

// ── Gentle fade only (for tab-like switches) ─────────────────────────────────
CustomTransitionPage<T> _fadeOnly<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    );

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
      // Auth flow – fade only
      GoRoute(path: '/splash',
          pageBuilder: (c, s) => _fadeOnly(context: c, state: s, child: const SplashScreen())),
      GoRoute(path: '/welcome',
          pageBuilder: (c, s) => _fadeOnly(context: c, state: s, child: const WelcomeScreen())),
      GoRoute(path: '/login',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const LoginScreen())),
      GoRoute(path: '/signup',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const SignupScreen())),
      GoRoute(
        path: '/otp',
        pageBuilder: (c, s) => _slideFade(context: c, state: s, child: OtpScreen(email: s.extra as String)),
      ),
      GoRoute(path: '/profile-setup',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const ProfileSetupScreen())),

      // Main app – fade (instant feel inside tab shell)
      GoRoute(path: '/home',
          pageBuilder: (c, s) => _fadeOnly(context: c, state: s, child: const HomeScreen())),

      // Session flow – slide in from right
      GoRoute(path: '/session/setup',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const SessionSetupScreen())),
      GoRoute(
        path: '/session/active',
        pageBuilder: (c, s) => _slideFade(
            context: c, state: s,
            child: const SessionActiveScreen()),
      ),
      GoRoute(
        path: '/session/summary',
        pageBuilder: (c, s) => _slideFade(
            context: c, state: s,
            child: SessionSummaryScreen(session: Map<String, dynamic>.from(s.extra as Map))),
      ),

      // Analytics
      GoRoute(path: '/analytics',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const AnalyticsScreen())),
      GoRoute(
        path: '/analytics/subject',
        pageBuilder: (c, s) => _slideFade(context: c, state: s,
            child: SubjectDetailScreen(subject: s.extra as String)),
      ),
      GoRoute(path: '/analytics/weekly-report',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const WeeklyReportScreen())),

      // AI
      GoRoute(path: '/ai/chat',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const AiChatScreen())),
      GoRoute(
        path: '/ai/quiz',
        pageBuilder: (c, s) => _slideFade(context: c, state: s,
            child: QuizScreen(quizData: s.extra as Map<String, dynamic>)),
      ),

      // Profile & Planner
      GoRoute(path: '/profile',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const ProfileScreen())),
      GoRoute(path: '/flashcards',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const FlashcardsScreen())),
      GoRoute(path: '/virtual-library',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const VirtualLibraryScreen())),
      GoRoute(path: '/rewards',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const RewardsScreen())),
      GoRoute(path: '/exam-planner',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const ExamPlannerScreen())),
      GoRoute(path: '/exam-planner/setup',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const ExamPlannerSetupScreen())),
      GoRoute(
        path: '/exam-planner/subject-info',
        pageBuilder: (c, s) => _slideFade(context: c, state: s, child: SubjectInfoScreen(subject: s.extra as String)),
      ),
      GoRoute(path: '/change-password',
          pageBuilder: (c, s) => _slideFade(context: c, state: s, child: const ChangePasswordScreen())),
    ],
    errorBuilder: (c, s) => Scaffold(
      body: Center(child: Text('Page not found: ${s.error}')),
    ),
  );
});
