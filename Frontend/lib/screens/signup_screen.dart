import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/animations.dart';
import '../app_theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).register(
          name: _nameCtrl.text.trim(),
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
              top: -80, right: -80,
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.accentTeal.withOpacity(0.12),
                    AppColors.accentTeal.withOpacity(0.0),
                  ]),
                ),
              ),
            ),
            // Gradient blob bottom-left
            Positioned(
              bottom: -60, left: -60,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withOpacity(0.09),
                    AppColors.primary.withOpacity(0.0),
                  ]),
                ),
              ),
            ),

            // ── Main content ───────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Back button row (always at top)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: FadeSlideIn(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PressButton(
                          scaleDown: 0.88,
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)],
                            ),
                            child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center everything else
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Header ─────────────────────────────
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 60),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.heroGradient,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                      ),
                                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create Account ✨',
                                          style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'Study smarter, not harder',
                                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Form card ──────────────────────────
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 120),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.07),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Name
                                      Text('Full Name', style: _labelStyle),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _nameCtrl,
                                        textCapitalization: TextCapitalization.words,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                                        decoration: _fieldDeco(hint: 'Your full name', icon: Icons.person_rounded),
                                        validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name' : null,
                                      ),
                                      const SizedBox(height: 14),

                                      // Email
                                      Text('Email', style: _labelStyle),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _emailCtrl,
                                        keyboardType: TextInputType.emailAddress,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                                        decoration: _fieldDeco(hint: 'you@example.com', icon: Icons.email_rounded),
                                        validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                                      ),
                                      const SizedBox(height: 14),

                                      // Password
                                      Text('Password', style: _labelStyle),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _passCtrl,
                                        obscureText: _obscure,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                                        decoration: _fieldDeco(
                                          hint: 'Min 8 characters',
                                          icon: Icons.lock_rounded,
                                          suffix: IconButton(
                                            icon: Icon(
                                              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                            onPressed: () => setState(() => _obscure = !_obscure),
                                          ),
                                        ),
                                        validator: (v) => v == null || v.length < 8 ? 'At least 8 characters' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Terms
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
                                child: Text(
                                  'By signing up, you agree to our Terms & Privacy Policy.',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textLight),
                                ),
                              ),

                              // CTA
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 200),
                                child: PrimaryButton(
                                  text: 'Create Account  →',
                                  isLoading: state.isLoading,
                                  onPressed: _signup,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Divider
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 260),
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
                              const SizedBox(height: 8),

                              // Login link
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 300),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Already have an account?',
                                        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
                                    TextButton(
                                      onPressed: () => context.pushReplacement('/login'),
                                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                                      child: Text('Log in',
                                          style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  InputDecoration _fieldDeco({required String hint, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.textLight, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8)),
      );
}
