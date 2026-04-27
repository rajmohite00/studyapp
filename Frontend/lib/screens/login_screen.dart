import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/animations.dart';
import '../app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;

    final state = ref.read(authStateProvider);
    if (state.isAuthenticated) context.go('/home');
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.error!),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authStateProvider);

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Gradient blob top-right
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.0),
                  ]),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      FadeSlideIn(
                        child: PressButton(
                          scaleDown: 0.88,
                          onTap: () => context.pop(),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)],
                            ),
                            child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Header
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gradient icon
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                              ),
                              child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome back 👋',
                              style: GoogleFonts.outfit(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Log in to continue your study journey',
                              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 15, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Form card
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.07),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email field
                              Text('Email', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'you@example.com',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.email_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                              ),
                              const SizedBox(height: 20),

                              // Password field
                              Text('Password', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                              ),
                            ],
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/otp', extra: _emailCtrl.text.trim()),
                          child: Text('Forgot password?', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // CTA Button
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 240),
                        child: PrimaryButton(
                          text: 'Log In  →',
                          isLoading: state.isLoading,
                          onPressed: _login,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Divider
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.divider)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or', style: GoogleFonts.outfit(color: AppColors.textLight, fontSize: 13)),
                            ),
                            const Expanded(child: Divider(color: AppColors.divider)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 340),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?", style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
                            TextButton(
                              onPressed: () => context.pushReplacement('/signup'),
                              child: Text('Sign up', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
