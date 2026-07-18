import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _navigationDone = false;
  bool _isTakingLong = false;
  Timer? _longWaitTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    // Show a friendly "Waking up server..." hint if it takes longer than 4 s
    _longWaitTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isTakingLong = true);
    });

    // Run session check after a short minimum display time (500 ms)
    Future.delayed(const Duration(milliseconds: 500), _checkSessionAndNavigate);
  }

  @override
  void dispose() {
    _longWaitTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Primary session-check logic — lives on the Splash Screen.
  ///
  /// 1. Checks StorageService.isSessionValid() (local, synchronous).
  /// 2. If the 7-day window has not expired, waits for AuthNotifier to finish
  ///    initialising (it may be fetching the user from cache or network).
  /// 3. Navigates to /home or /welcome.
  Future<void> _checkSessionAndNavigate() async {
    if (!mounted || _navigationDone) return;

    // Fast path: session locally invalid — no need to wait for network
    if (!StorageService.isSessionValid()) {
      await StorageService.clearSession();
      _navigate('/welcome');
      return;
    }

    // Session looks valid — wait for AuthNotifier to fully initialise
    // (it restores from cache or makes a network call)
    final auth = ref.read(authStateProvider);
    if (auth.initialized) {
      _navigate(auth.isAuthenticated ? '/home' : '/welcome');
    }
    // If not yet initialized, the listener below will catch it
  }

  void _navigate(String route) {
    if (!mounted || _navigationDone) return;
    _navigationDone = true;
    _longWaitTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Also listen reactively in case auth initialises after the delay
    ref.listen<AuthState>(authStateProvider, (_, next) {
      if (next.initialized && !_navigationDone) {
        _navigate(next.isAuthenticated ? '/home' : '/welcome');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'AI Study Coach',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Study Smarter.',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
              if (_isTakingLong) ...[
                const SizedBox(height: 16),
                Text(
                  'Waking up server...',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

