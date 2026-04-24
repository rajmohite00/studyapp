import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _minDurationPassed = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _minDurationPassed = true;
        });
        _checkAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAndNavigate() {
    final auth = ref.read(authStateProvider);
    if (_minDurationPassed && auth.initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(auth.isAuthenticated ? '/home' : '/welcome');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes just in case it initializes after the delay
    ref.listen(authStateProvider, (previous, next) {
      if (next.initialized) {
        _checkAndNavigate();
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
              Text(
                'AI Study Coach',
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Study Smarter.',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
