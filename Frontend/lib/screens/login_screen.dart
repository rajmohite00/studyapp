import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authStateProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;
    final s = ref.read(authStateProvider);
    if (s.isAuthenticated) context.go('/home');
    if (s.error != null) _showError(s.error!);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                      // ── Brand logo ───────────────────────────
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: AppColors.primary, size: 32),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Heading ──────────────────────────────
                      Center(
                        child: Text('Welcome back',
                            style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5)),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text('Sign in to your account',
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 40),

                      // ── Email ────────────────────────────────
                      _FieldLabel('Email address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textPrimary),
                        decoration: _inputDeco(
                            hint: 'you@university.edu',
                            icon: Icons.email_outlined),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // ── Password ─────────────────────────────
                      _FieldLabel('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textPrimary),
                        decoration: _inputDeco(
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Minimum 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ── Forgot password ───────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            final email = _emailCtrl.text.trim();
                            context.push('/otp', extra: email.isEmpty ? 'user@example.com' : email);
                          },
                          child: Text('Forgot Password?',
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Sign in button ────────────────────────
                      _GradientButton(
                        label: 'Sign In',
                        isLoading: state.isLoading,
                        onTap: state.isLoading ? null : _submit,
                      ),
                      const SizedBox(height: 24),

                      // ── Divider ───────────────────────────────
                      Row(children: [
                        const Expanded(child: Divider(color: Color(0xFFE8E8EE))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight,
                                  letterSpacing: 1)),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE8E8EE))),
                      ]),
                      const SizedBox(height: 20),

                      // ── Google button ─────────────────────────
                      _GoogleButton(),
                      const Spacer(),
                      const SizedBox(height: 32),

                      // ── Sign up link ──────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => context.pushReplacement('/signup'),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                  fontSize: 14, color: AppColors.textSecondary),
                              children: [
                                const TextSpan(text: "Don't have an account?  "),
                                TextSpan(
                                  text: 'Sign Up',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
            color: AppColors.textLight, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: suffix,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F8FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8EE))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8EE))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
      );
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  const _GradientButton(
      {required this.label, required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? AppColors.heroGradient
              : const LinearGradient(
                  colors: [Color(0xFFCCCCCC), Color(0xFFCCCCCC)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // wire Google OAuth when ready
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8EE), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              child: Text('G',
                  style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4285F4))),
            ),
            const SizedBox(width: 12),
            Text('Continue with Google',
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
