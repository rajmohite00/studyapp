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
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
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
            // Gradient blob top-left
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.accentPurple.withOpacity(0.18),
                    AppColors.accentPurple.withOpacity(0.0),
                  ]),
                ),
              ),
            ),
            // Gradient blob bottom-right
            Positioned(
              bottom: 60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.accentTeal.withOpacity(0.14),
                    AppColors.accentTeal.withOpacity(0.0),
                  ]),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button + title row
                      FadeSlideIn(
                        child: Row(
                          children: [
                            PressButton(
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
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Account ✨',
                                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                                ),
                                Text(
                                  'Join thousands studying smarter',
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form card
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              TextFormField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Full Name',
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(10),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 2 ? 'Enter your name' : null,
                              ),
                              const SizedBox(height: 10),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Email address',
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(10),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.email_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                              ),
                              const SizedBox(height: 10),

                              // Password
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Password (8+ chars)',
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(10),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 8 ? 'Min 8 characters' : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Terms note
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'By signing up, you agree to our Terms & Privacy Policy.',
                          style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textLight, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CTA Button
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 260),
                        child: PrimaryButton(
                          text: 'Create Account  →',
                          isLoading: state.isLoading,
                          onPressed: _register,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 320),
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
                      const SizedBox(height: 16),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 360),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account?', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
                            TextButton(
                              onPressed: () => context.pushReplacement('/login'),
                              child: Text('Log in', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
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

class _HighlightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HighlightChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
